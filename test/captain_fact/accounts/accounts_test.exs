defmodule CaptainFact.AccountsTest do
  use CaptainFact.DataCase
  use Bamboo.Test

  alias CaptainFact.Accounts
  alias CaptainFact.Actions.Analysers.{Reputation, Achievements}

  describe "reset_password_requests" do
    alias CaptainFact.Accounts.ResetPasswordRequest
    alias CaptainFact.Accounts.UserPermissions.PermissionsError

    # Request

    test "token gets generated and sent by mail" do
      Repo.delete_all(ResetPasswordRequest)
      user = insert(:user)

      Accounts.reset_password!(user.email, "127.0.0.1")

      assert Repo.aggregate(ResetPasswordRequest, :count, :token) == 1
      req = Repo.get_by!(ResetPasswordRequest, user_id: user.id)
      refute is_nil(req.token) or String.length(req.token) < 128
      assert_delivered_email CaptainFact.Email.reset_password_request_mail(req)
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

  describe "invitation_requests" do
    test "invitation request get created with given invited_by user" do
      email = "test@email.com"
      user = insert(:user)
      {:ok, req} = Accounts.request_invitation(email, user)
      assert is_nil(req.token), "don't generate token before necessary"
      assert user.id == req.invited_by_id
      assert email == req.email
    end

    test "send a mail when calling send_invite/1" do
      req = insert(:invitation_request)
      Accounts.send_invite(req)
      assert_delivered_email CaptainFact.Email.invite_user_email(req)
    end

    test "send mails when calling send_invites/1" do
      nb_invites = 10
      requests = insert_list(nb_invites, :invitation_request)
      Accounts.send_invites(nb_invites)
      Enum.each(requests, fn req ->
        assert_delivered_email CaptainFact.Email.invite_user_email(req)
      end)
    end

    test "multiple requests only insert one time but doesn't crash" do
      email = "test@email.com"
      user = insert(:user)
      {:ok, req} = Accounts.request_invitation(email)
      {:ok, req2} = Accounts.request_invitation(email)
      {:ok, req3} = Accounts.request_invitation(email, user)

      assert req.id == req2.id
      assert req2.id == req3.id
    end

    test "cannot insert with bad email" do
      assert {:error, "invalid_email"} == Accounts.request_invitation("toto@yopmail.fr")
      assert {:error, "invalid_email"} == Accounts.request_invitation("toto@")
      assert {:error, "invalid_email"} == Accounts.request_invitation("xxxxxxxxx")
    end

    test "re-asking for an invitation reset invitation_sent boolean to false" do
      req = insert(:invitation_request, %{invitation_sent: true})
      {:ok, req_updated} = Accounts.request_invitation(req.email)
      assert req_updated.invitation_sent == false
    end

    # TODO What if user already have an account and request an invitation ?
  end

  describe "create_account" do
    test "requires a valid invitation token" do
      assert Accounts.create_account(%{}, nil) == {:error, "invalid_invitation_token"}
      assert Accounts.create_account(%{}, "") == {:error, "invalid_invitation_token"}
      assert Accounts.create_account(%{}, "zzzzz") == {:error, "invalid_invitation_token"}
    end

    test "create an account if a valid user is given" do
      invit = insert(:invitation_request)
      user_params = build_user_params()
      {:ok, created} = Accounts.create_account(user_params, invit.token)
      assert user_params.username == created.username
      assert user_params.email == created.email
    end

    test "can create an account with auto-generated username only if explicitly requested" do
      invit = insert(:invitation_request)
      user_params = Map.delete(build_user_params(), :username)

      {:error, %Ecto.Changeset{}} = # Without username, no allow_empty_username
        Accounts.create_account(user_params, invit.token)
      {:error, %Ecto.Changeset{}} = # With empty username, no allow_empty_username
        Accounts.create_account(Map.put(user_params, :username, ""), invit.token)
      {:ok, created} = # Without username, allow_empty_username
        Accounts.create_account(user_params, invit.token, allow_empty_username: true)

      assert user_params.email == created.email
      assert String.starts_with?(created.username, Accounts.UsernameGenerator.username_prefix())
    end

    test "store provider infos" do
      invit = insert(:invitation_request)
      user_params = build_user_params()
      provider_params = %{fb_user_id: "4242424242"}

      Accounts.create_account(user_params, invit.token, provider_params: provider_params)
    end

    test "delete invitation request after creating the user" do
      Repo.delete_all(Accounts.InvitationRequest)
      invit = insert(:invitation_request)
      user_params = build_user_params()
      Accounts.create_account(user_params, invit.token)
      assert Repo.get(Accounts.InvitationRequest, invit.id) == nil
    end

    test "sends an email to welcome the user" do
      invit = insert(:invitation_request)
      user_params = build_user_params()
      {:ok, user} = Accounts.create_account(user_params, invit.token)
      assert_delivered_email CaptainFact.Email.welcome_email(user)
    end

    defp build_user_params() do
      build(:user)
      |> Map.take([:email, :username])
      |> Map.put(:password, "xs45;%%5s")
    end
  end

  describe "confirm email" do
    test "set email_confirmed to true, reset the token and update reputation" do
      user = insert(:user)
      Accounts.confirm_email!(user.email_confirmation_token)
      Reputation.force_update()
      Achievements.force_update()
      updated_user = Repo.get(Accounts.User, user.id)

      assert updated_user.email_confirmed
      assert updated_user.email_confirmation_token == nil
      assert user.reputation < updated_user.reputation
    end
  end

  describe "achievements" do
    test "unlock achievements" do
      user = insert(:user)
      achievement = Repo.get_by!(Accounts.Achievement, slug: "bulletproof")
      Accounts.unlock_achievement(user, achievement.slug)
      updated = Repo.get(Accounts.User, user.id)
      assert achievement.id in updated.achievements
    end
  end

end