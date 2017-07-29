defmodule CaptainFact.Accounts do
  @moduledoc """
  The boundary for the Accounts system.
  """

  import Ecto.Query, warn: false
  alias CaptainFact.Repo

  alias CaptainFact.Accounts.{User, ResetPasswordRequest, UserPermissions}

  @max_ip_reset_requests 3
  @request_validity 48 * 60 * 60 # 48 hours


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

  def confirm_password_reset!(token, new_password) do
    updated_user =
      check_reset_password_token!(token)
      |> User.password_changeset(%{password: new_password})
      |> Repo.update!()

    Repo.delete_all(from r in ResetPasswordRequest, where: r.user_id == ^updated_user.id)
    updated_user
  end
end
