defmodule CaptainFact.Accounts do
  @moduledoc """
  The boundary for the Accounts system.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Ecto.Multi
  alias CaptainFact.Repo
  alias CaptainFact.Email

  alias CaptainFact.Accounts.{User, ResetPasswordRequest, UserPermissions, InvitationRequest, Achievement}
  alias CaptainFact.Accounts.{UsernameGenerator, ForbiddenEmailProviders}
  alias CaptainFact.Actions.Recorder
  alias CaptainFact.TokenGenerator


  @max_ip_reset_requests 3
  @request_validity 48 * 60 * 60 # 48 hours

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
    case Map.get(user_params, "username") || Map.get(user_params, :username) do
      username when allow_empty_username and (is_nil(username) or username == "") ->
        Map.get(user_params, "email") || Map.get(user_params, :email)
        |> create_account_without_username(user_params, provider_params)
      _ ->
        do_create_account(user_params, provider_params)
    end
    |> after_create(invitation_token)
  end

  defp after_create(error = {:error, _}, _), do: error
  defp after_create(result = {:ok, user}, invitation_token) do
    # We willingly delete token using `invitation_token` string because we accept having
    # multiple invitations with the same token
    if invitation_token, do: delete_invitation(invitation_token)

    # Send welcome mail
    send_welcome_email(user)

    # Return final result
    result
  end

  @doc"""
  Send user a welcome email, with a link to confirm it (only if not already confirmed)
  """
  def send_welcome_email(%User{email_confirmed: true}), do: nil
  def send_welcome_email(user) do
    CaptainFact.Mailer.deliver_later(CaptainFact.Email.welcome_email(user))
  end

  @social_network_achievement 6
  defp do_create_account(user_params, provider_params) do
    User.registration_changeset(%User{}, user_params)
    |> User.provider_changeset(provider_params)
    |> Repo.insert()
  end

  defp create_account_without_username(email, params, provider_params) do
    Multi.new
    |> Multi.insert(:base_user,
         %User{username: temporary_username(email)}
         |> User.registration_changeset(Map.drop(params, [:username, "username"]))
         |> Ecto.Changeset.update_change(:achievements, fn list ->
              if Map.has_key?(provider_params, :fb_user_id),
                do: Enum.uniq([@social_network_achievement | list]), else: list
            end)
         |> User.provider_changeset(provider_params)
       )
    |> Multi.run(:final_user, fn %{base_user: user} ->
         User.changeset(user, %{})
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
    |> Base.encode64
    |> String.slice(-8..-2)
    |> (fn res -> "temporary-#{res}" end).()
  end

  # ---- Confirm email ----

  def confirm_email!(token) do
    user =
      Repo.get_by(User, email_confirmation_token: token)
      |> User.changeset_confirm_email(true)
      |> Repo.update!()

    Recorder.record!(user, :email_confirmed, :user)
  end

  # ---- Achievements -----

  def unlock_achievement(user = %User{id: user_id}, slug) when is_binary(slug) do
    achievement = Repo.get_by!(Achievement, slug: slug)
    if achievement.id in user.achievements do
      {:ok, user} # Don't update user if achievement is already unlocked
    else
      Repo.transaction(fn ->
        user =
          User
          |> where(id: ^user_id)
          |> lock("FOR UPDATE")
          |> Repo.one!()

        Repo.update!(Ecto.Changeset.change(user, achievements: Enum.uniq([achievement.id | user.achievements])))
      end)
    end
  end

  # ---- Reset Password ----

  @doc"""
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
    |> Email.reset_password_request_mail()
    |> CaptainFact.Mailer.deliver_later()
  end

  @doc """
  Returns the user associated with given reset password token or raise
  """
  def check_reset_password_token!(token) do
    date_limit =
      DateTime.utc_now
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
      check_reset_password_token!(token)
      |> User.password_changeset(%{password: new_password})
      |> Repo.update!()

    Repo.delete_all(from r in ResetPasswordRequest, where: r.user_id == ^updated_user.id)
    updated_user
  end

  # ---- Invitations ----

  @doc """
  Request an invitation for given email
  """
  def request_invitation(email, user \\ nil)
  def request_invitation(email, invited_by_id)
  when is_nil(invited_by_id) or is_integer(invited_by_id) do
    with true <- Regex.match?(User.email_regex, email),
         false <- ForbiddenEmailProviders.is_forbidden?(email)
    do
      case Repo.get_by(InvitationRequest, email: email) do
        nil ->
          %InvitationRequest{}
          |> InvitationRequest.changeset(%{email: email, invited_by_id: invited_by_id})
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
  def request_invitation(email, %User{id: id}), do: request_invitation(email, id)

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

  @default_token_length 12
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
    |> CaptainFact.Email.invite_user_email()
    |> CaptainFact.Mailer.deliver_later()

    # Email sent successfuly
    Repo.update!(InvitationRequest.changeset_sent(request, true))
  end

  def generate_invites(number), do: generate_invites(number, TokenGenerator.generate(@default_token_length))
  def generate_invites(number, token) do
    time = Ecto.DateTime.utc
    Repo.insert_all(InvitationRequest, (for _ <- 1..number, do: %{token: token, inserted_at: time, updated_at: time}))
    frontend_url = Application.fetch_env!(:captain_fact, :frontend_url)
    Logger.info("Generated #{number} invites for token #{token}. Url: #{frontend_url}/signup?invitation_token=#{token}")
  end

  def get_invitation_for_token(token),
    do: InvitationRequest |> where(token: ^token) |> limit(1) |> Repo.one()

  defp delete_invitation(invitation_token) do
    case get_invitation_for_token(invitation_token) do
      nil -> {:error, nil}
      invit ->
        Repo.delete(invit)
        Logger.debug("Invitation #{invit.id} for token #{invit.token} has been consumed")
    end
  end
end
