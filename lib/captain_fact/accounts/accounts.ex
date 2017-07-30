defmodule CaptainFact.Accounts do
  @moduledoc """
  The boundary for the Accounts system.
  """

  import Ecto.Query, warn: false
  alias CaptainFact.Repo

  alias CaptainFact.Accounts.{User, ResetPasswordRequest, UserPermissions, InvitationRequest}

  @max_ip_reset_requests 3
  @request_validity 48 * 60 * 60 # 48 hours

  # ---- Reset Password ----

  @doc """
  Returns the user associated with given reset password token
  """
  def reset_password!(email, source_ip_address) when is_binary(source_ip_address) do
    user = Repo.get_by!(User, email: email)
    nb_ip_requests =
      ResetPasswordRequest
      |> where([r], r.source_ip == ^source_ip_address)
      |> Repo.aggregate(:count, :token)

    if nb_ip_requests > @max_ip_reset_requests do
      throw UserPermissions.PermissionsError
    end

    %ResetPasswordRequest{}
    |> ResetPasswordRequest.changeset(%{user_id: user.id, source_ip: source_ip_address})
    |> Repo.insert!()
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
    |> where([i], i.invitation_sent == false)
    |> order_by([i], i.updated_at)
    |> limit(^nb_invites)
    |> Repo.all()
    |> Enum.each(&send_invite/1)
  end

  @doc """
  Send invite to the given invitation request
  """
  def send_invite(request = %InvitationRequest{token: nil}),
    do: send_invite(Repo.update!(InvitationRequest.changeset_token(request)))
  def send_invite(request = %InvitationRequest{}) do
    # TODO Send mail
    # Email sent successfuly
    Repo.update!(InvitationRequest.changeset_sent(request, true))
  end
end
