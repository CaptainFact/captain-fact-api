defmodule CaptainFact.AccountsTest do
  use CaptainFact.DataCase

  alias CaptainFact.Accounts

  describe "reset_password_requests" do
    alias CaptainFact.Accounts.ResetPasswordRequest
    alias CaptainFact.UserPermissions.PermissionsError

    # Request

    test "token gets generated" do
      Repo.delete_all(ResetPasswordRequest)
      user = insert(:user)
      Accounts.reset_password!(user.email, "127.0.0.1")
      assert Repo.aggregate(ResetPasswordRequest, :count, :token) == 1
      req = Repo.get_by!(ResetPasswordRequest, user_id: user.id)
      refute is_nil(req.token) or String.length(req.token) != 254
    end

    test "a single ip cannot make too much requests" do
      # With a single user
      Repo.delete_all(ResetPasswordRequest)
      user = insert(:user)
      assert catch_throw(
        for _ <- 0..10, do: Accounts.reset_password!(user.email, "127.0.0.1")
      ) == PermissionsError

      # With changing users
      Repo.delete_all(ResetPasswordRequest)
      assert catch_throw(
        for _ <- 0..10 do
          user = insert(:user)
          Accounts.reset_password!(user.email, "127.0.0.1")
        end
      ) == PermissionsError
    end

    #    test "sends an email with the token"

    # Verify
    test "verify token" do
      user = insert(:user)
      req =
        %ResetPasswordRequest{}
        |> ResetPasswordRequest.changeset(%{user_id: user.id, source_ip: "127.0.0.1"})
        |> Repo.insert!()

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.check_reset_password_token!("InvalidToken")
      end
      tokenUser = Accounts.check_reset_password_token!(req.token)
      assert tokenUser.id == user.id
    end

    test "verify token after expired" do
      user = insert(:user)
      req =
        %ResetPasswordRequest{}
        |> ResetPasswordRequest.changeset(%{user_id: user.id, source_ip: "127.0.0.1"})
        |> Repo.insert!()
        |> Ecto.Changeset.change(inserted_at: ~N[2012-12-12 12:12:12])
        |> Repo.update!()


      assert_raise Ecto.NoResultsError, fn ->
        Accounts.check_reset_password_token!(req.token)
      end
    end

    # Confirm

    test "changes user password and delete all user's requests'" do
      user = insert(:user)
      new_password = "iHaveBeé€nChangeeeeed!"
      req =
        %ResetPasswordRequest{}
        |> ResetPasswordRequest.changeset(%{user_id: user.id, source_ip: "127.0.0.1"})
        |> Repo.insert!()

      updatedUser = Accounts.confirm_password_reset!(req.token, new_password)
      refute Comeonin.Bcrypt.checkpw(new_password, user.encrypted_password)
      assert Comeonin.Bcrypt.checkpw(new_password, updatedUser.encrypted_password)

      nb_requests =
        ResetPasswordRequest
        |> where([u], u.user_id == ^user.id)
        |> Repo.aggregate(:count, :token)
      assert nb_requests == 0
    end
  end
end
