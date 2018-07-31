defmodule CaptainFact.Accounts do
  @moduledoc """
  The boundary for the Accounts system.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Ecto.Multi
  alias DB.Repo
  alias DB.Type.Achievement
  alias DB.Schema.User
  alias DB.Schema.ResetPasswordRequest
  alias DB.Schema.InvitationRequest
  alias DB.Utils.TokenGenerator

  alias CaptainFactMailer.Email
  alias CaptainFact.Accounts.{UsernameGenerator, UserPermissions}
  alias CaptainFact.Actions.Recorder
  alias CaptainFact.Authenticator

  alias Kaur.Result

  @max_ip_reset_requests 3
  # 48 hours
  @request_validity 48 * 60 * 60

  # ---- User creation ----

  @doc """
  Create an account with given user `params`

  Raise if `invitation_token` is not valid

  Returns {:ok, %User{}} if success
  In case of error, return can be :
    * {:error, %Ecto.Changeset{}}
    * {:error, message}
    * {:error, nil} (unknown error)
  """
  def create_account(_, _, _ \\ [])

  def create_account(_, nil, _),
    do: {:error, "invalid_invitation_token"}

  def create_account(user_params, invitation_token, opts) when is_binary(invitation_token),
    do: create_account(user_params, get_invitation_for_token(invitation_token), opts)

  def create_account(user_params, %InvitationRequest{token: invitation_token}, opts) do
    allow_empty_username = Keyword.get(opts, :allow_empty_username, false)
    provider_params = Keyword.get(opts, :provider_params, %{})

    # Do create user
    user_params
    |> create_account_from_params(provider_params, allow_empty_username)
    |> after_create(invitation_token)
  end

  defp create_account_from_params(user_params, provider_params, allow_empty_username) do
    case Map.get(user_params, "username") || Map.get(user_params, :username) do
      username when allow_empty_username and (is_nil(username) or username == "") ->
        email = Map.get(user_params, "email") || Map.get(user_params, :email)
        create_account_without_username(email, user_params, provider_params)

      _ ->
        do_create_account(user_params, provider_params)
    end
  end

  defp after_create(error = {:error, _}, _), do: error

  defp after_create(result = {:ok, user}, invitation_token) do
    # We willingly delete token using `invitation_token` string because we
    # accept having multiple invitations with the same token
    if invitation_token, do: delete_invitation(invitation_token)

    # Send welcome mail or directly confirm email if third party provider
    if user.fb_user_id == nil do
      send_welcome(user)
    else
      confirm_email!(user)
    end

    # Return final result
    result
  end

  @doc """
  Update user
  """
  def update(user, params) do
    UserPermissions.check!(user, :update, :user)

    user
    |> User.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        Recorder.record(user, :update, :user)
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Delete User and its infos from DB
  Revoke and unlink every third parties authenticator accounts
  """
  @spec delete_account(%User{}) :: Kaur.Result.t()
  def delete_account(user = %User{}) do
    user
    |> Authenticator.dissociate_third_party(:facebook)
    |> Result.map(&Repo.delete(&1, []))
  end

  @doc """
  Send user a welcome email, with a link to confirm it (only if not already confirmed)
  """
  def send_welcome(%User{email_confirmed: true}), do: nil

  def send_welcome(user) do
    CaptainFactMailer.deliver_later(CaptainFactMailer.Email.welcome(user))
  end

  defp do_create_account(user_params, provider_params) do
    %User{}
    |> User.registration_changeset(user_params)
    |> User.provider_changeset(provider_params)
    |> Repo.insert()
  end

  defp create_account_without_username(nil, _, _), do: {:error, "invalid_email"}

  defp create_account_without_username(email, params, provider_params) do
    Multi.new()
    |> Multi.insert(
      :base_user,
      %User{username: temporary_username(email)}
      |> User.registration_changeset(Map.drop(params, [:username, "username"]))
      |> Ecto.Changeset.update_change(:achievements, fn list ->
        if Map.has_key?(provider_params, :fb_user_id),
          do: Enum.uniq([Achievement.get(:social_networks) | list]),
          else: list
      end)
      |> User.provider_changeset(provider_params)
    )
    |> Multi.run(:final_user, fn %{base_user: user} ->
      user
      |> User.changeset(%{})
      |> Ecto.Changeset.put_change(:username, UsernameGenerator.generate(user.id))
      |> Repo.update()
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{final_user: user}} -> {:ok, user}
    end
  end

  defp temporary_username(email) do
    :crypto.hash(:sha256, email)
    |> Base.encode64()
    |> String.slice(-8..-2)
    |> (fn res -> "temporary-#{res}" end).()
  end

  # ---- Picture ----

  @doc """
  Fetch a user picture from given URL.

  Returns `{:ok, updated_user}` or `{:error, error}`
  """
  def fetch_picture(_, picture_url) when picture_url in [nil, ""],
    do: {:error, :invalid_path}

  def fetch_picture(user, picture_url) do
    if Application.get_env(:captain_fact, :env) != :test do
      case DB.Type.UserPicture.store({picture_url, user}) do
        {:ok, picture} ->
          Repo.update(User.changeset_picture(user, picture))

        error ->
          error
      end
    else
      # Don't store files in tests
      Repo.update(User.changeset_picture(user, picture_url))
    end
  end

  # ---- Confirm email ----

  @doc """
  Confirm user email. Ignored if already confirmed.
  """
  def confirm_email!(token) when is_binary(token),
    do: confirm_email!(Repo.get_by(User, email_confirmation_token: token))

  def confirm_email!(%User{email_confirmed: true}),
    do: nil

  def confirm_email!(user = %User{email_confirmed: false}) do
    updated_user =
      user
      |> User.changeset_confirm_email(true)
      |> Repo.update!()

    Recorder.admin_record!(:email_confirmed, :user, %{target_user_id: user.id})
    updated_user
  end

  # ---- Achievements -----

  @doc """
  Unlock given achievement. `achievement` can be passed as an integer or as the
  atom representation. See `DB.Type.Achievement` for more info.
  """
  def unlock_achievement(user, achievement) when is_atom(achievement),
    do: unlock_achievement(user, Achievement.get(achievement))

  def unlock_achievement(user, achievement) when is_integer(achievement) do
    if achievement in user.achievements do
      # Don't update user if achievement is already unlocked
      {:ok, user}
    else
      Repo.transaction(fn ->
        user
        |> lock_user()
        |> User.changeset_achievement(achievement)
        |> Repo.update!()
      end)
    end
  end

  # ---- Onboarding Steps ----

  @doc """
  add the given `step` to `user`

  Returns `{:ok, updated_user}` or `{:error, reason}`.
  """
  @spec complete_onboarding_step(%User{}, integer) :: {:ok, %User{}} | {:error, any}
  def complete_onboarding_step(user = %User{}, step)
      when is_integer(step) do
    user
    |> User.changeset_completed_onboarding_steps(step)
    |> Repo.update()
  end

  @doc """
  add the given `steps` to `user`

  Returns `{:ok, updated_user}` or `{:error, changeset}
  """
  @spec complete_onboarding_steps(%User{}, list) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def complete_onboarding_steps(user = %User{}, steps)
      when is_list(steps) do
    user
    |> User.changeset_completed_onboarding_steps(steps)
    |> Repo.update()
  end

  @doc """
  reinitialize onboarding steps for `user`

  Returns `{:ok, updated_user}` or `{:error, reason}`.
  """
  def delete_onboarding(user = %User{}) do
    user
    |> User.changeset_delete_onboarding()
    |> Repo.update()
  end

  # ---- Link speaker ----

  @doc """
  Link a speaker to given user.
  """
  def link_speaker(user, speaker) do
    user
    |> User.changeset_link_speaker(speaker)
    |> Repo.update()
  end

  # ---- Reputation ----

  @doc """
  Update user retutation with `user.reputation + diff`. Properly lock user in DB
  to ensure no cheating can be made.
  """
  def update_reputation(user, diff) when is_integer(diff) do
    Repo.transaction(fn ->
      user
      |> lock_user()
      |> User.reputation_changeset(diff)
      |> Repo.update!()
    end)
  end

  # ---- Reset Password ----

  @doc """
  Returns the user associated with given reset password token
  """
  def reset_password!(email, source_ip_address) when is_binary(source_ip_address) do
    user = Repo.get_by!(User, email: email)

    # Ensure not flooding
    nb_ip_requests =
      ResetPasswordRequest
      |> where([r], r.source_ip == ^source_ip_address)
      |> Repo.aggregate(:count, :token)

    if nb_ip_requests > @max_ip_reset_requests do
      raise %UserPermissions.PermissionsError{message: "limit_reached"}
    end

    # Generate request
    request =
      %ResetPasswordRequest{}
      |> ResetPasswordRequest.changeset(%{user_id: user.id, source_ip: source_ip_address})
      |> Repo.insert!()

    # Email request
    request
    |> Map.put(:user, user)
    |> Email.reset_password_request()
    |> CaptainFactMailer.deliver_later()
  end

  @doc """
  Returns the user associated with given reset password token or raise
  """
  def check_reset_password_token!(token) do
    date_limit =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.add(-@request_validity, :second)

    User
    |> join(:inner, [u], r in ResetPasswordRequest, r.user_id == u.id)
    |> where([u, r], r.token == ^token)
    |> where([u, r], r.inserted_at >= ^date_limit)
    |> Repo.one!()
  end

  @doc """
  Changes user password
  """
  def confirm_password_reset!(token, new_password) do
    updated_user =
      token
      |> check_reset_password_token!()
      |> User.password_changeset(%{password: new_password})
      |> Repo.update!()

    Repo.delete_all(from(r in ResetPasswordRequest, where: r.user_id == ^updated_user.id))
    updated_user
  end

  # ---- Invitations ----

  @doc """
  Request an invitation for given email
  """
  def request_invitation(email, invited_by_id \\ nil, locale \\ nil)

  def request_invitation(email, invited_by_id, locale)
      when is_nil(invited_by_id) or is_integer(invited_by_id) do
    with true <- Regex.match?(User.email_regex(), email),
         false <- Burnex.is_burner?(email) do
      case Repo.get_by(InvitationRequest, email: email) do
        nil ->
          %InvitationRequest{}
          |> InvitationRequest.changeset(%{
            email: email,
            invited_by_id: invited_by_id,
            locale: locale
          })
          |> Repo.insert()

        %{invitation_sent: true} = invit ->
          Repo.update(InvitationRequest.changeset_sent(invit, false))

        request ->
          {:ok, request}
      end
    else
      _ -> {:error, "invalid_email"}
    end
  end

  def request_invitation(email, %User{id: id}, locale),
    do: request_invitation(email, id, locale)

  @doc """
  Send `nb_invites` invitations to most recently updated users
  """
  def send_invites(nb_invites) do
    InvitationRequest
    |> where([i], not is_nil(i.email))
    |> where([i], i.invitation_sent == false)
    |> order_by([i], i.updated_at)
    |> preload(:invited_by)
    |> limit(^nb_invites)
    |> Repo.all()
    |> Enum.each(&send_invite/1)
  end

  @default_token_length 8
  @doc """
  Send invite to the given email or invitation request
  """
  def send_invite(email) when is_binary(email) do
    {:ok, request} = request_invitation(email)
    send_invite(request)
  end

  def send_invite(request = %InvitationRequest{token: nil}) do
    request
    |> InvitationRequest.changeset_token(TokenGenerator.generate(@default_token_length))
    |> Repo.update!()
    |> send_invite()
  end

  def send_invite(request = %InvitationRequest{}) do
    request
    |> Repo.preload(:invited_by)
    |> CaptainFactMailer.Email.invitation_to_register()
    |> CaptainFactMailer.deliver_later()

    # Email sent successfuly
    Repo.update!(InvitationRequest.changeset_sent(request, true))
  end

  @doc """
  Generate `number` invitations. You can specify a custom `token`
  """
  def generate_invites(number),
    do: generate_invites(number, TokenGenerator.generate(@default_token_length))

  def generate_invites(number, token) do
    time = Ecto.DateTime.utc()

    Repo.insert_all(
      InvitationRequest,
      for(_ <- 1..number, do: %{token: token, inserted_at: time, updated_at: time})
    )

    frontend_url = Application.fetch_env!(:captain_fact, :frontend_url)

    Logger.info(
      "Generated #{number} invites for token #{token}. Url: #{frontend_url}/signup?invitation_token=#{
        token
      }"
    )
  end

  @doc """
  Return an invitation for given token
  """
  def get_invitation_for_token(token),
    do: InvitationRequest |> where(token: ^token) |> limit(1) |> Repo.one()

  defp delete_invitation(invitation_token) do
    case get_invitation_for_token(invitation_token) do
      nil ->
        {:error, nil}

      invit ->
        Repo.delete(invit)

        Logger.debug(fn ->
          "Invitation #{invit.id} for token #{invit.token} has been consumed"
        end)
    end
  end

  # ---- Newsletter ----

  def send_newsletter(subject, html_body, locale_filter \\ nil) do
    User
    |> filter_newsletter_targets(locale_filter)
    |> Repo.all()
    |> Enum.map(&CaptainFactMailer.Email.newsletter(&1, subject, html_body))
    |> Enum.map(&CaptainFactMailer.deliver_later/1)
    |> Enum.count()
  end

  defp filter_newsletter_targets(query, nil), do: where(query, [u], u.newsletter == true)

  defp filter_newsletter_targets(query, locale),
    do: where(query, [u], u.newsletter == true and u.locale == ^locale)

  # ---- Private Utils ----

  defp lock_user(%User{id: id}), do: lock_user(id)

  defp lock_user(user_id) do
    User
    |> where(id: ^user_id)
    |> lock("FOR UPDATE")
    |> Repo.one!()
  end
end
