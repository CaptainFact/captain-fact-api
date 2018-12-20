defmodule CF.AccountsTest do
  use CF.DataCase
  use Bamboo.Test

  alias CF.Accounts
  alias CF.Accounts.Invitations
  alias CF.Jobs.Reputation

  alias DB.Schema.User

  alias Kaur.Result

  describe "update user" do
    test "check user is updated" do
      user = insert(:user)
      {:ok, updated_user} = Accounts.update(user, %{name: "tototest"})
      assert user.name != updated_user.name
    end
  end

  describe "reset_password_requests" do
    alias DB.Schema.ResetPasswordRequest
    alias CF.Accounts.UserPermissions.PermissionsError

    # Request

    test "token gets generated and sent by mail" do
      Repo.delete_all(ResetPasswordRequest)
      user = insert(:user)

      Accounts.reset_password!(user.email, "127.0.0.1")

      assert Repo.aggregate(ResetPasswordRequest, :count, :token) == 1

      req =
        ResetPasswordRequest
        |> preload(:user)
        |> Repo.get_by!(user_id: user.id)

      refute is_nil(req.token) or String.length(req.token) < 128
      assert_delivered_email(CF.Mailer.Email.reset_password_request(req))
    end

    test "a single ip cannot make too much requests" do
      # With a single user
      Repo.delete_all(ResetPasswordRequest)
      user = insert(:user)

      assert_raise PermissionsError, fn ->
        for _ <- 0..10, do: Accounts.reset_password!(user.email, "127.0.0.1")
      end

      # With changing users
      Repo.delete_all(ResetPasswordRequest)

      assert_raise PermissionsError, fn ->
        for _ <- 0..10, do: Accounts.reset_password!(insert(:user).email, "127.0.0.1")
      end
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

      user_from_token = Accounts.check_reset_password_token!(req.token)
      assert user_from_token.id == user.id
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

      updated_user = Accounts.confirm_password_reset!(req.token, new_password)
      refute Bcrypt.verify_pass(new_password, user.encrypted_password)
      assert Bcrypt.verify_pass(new_password, updated_user.encrypted_password)

      nb_requests =
        ResetPasswordRequest
        |> where([u], u.user_id == ^user.id)
        |> Repo.aggregate(:count, :token)

      assert nb_requests == 0
    end
  end

  describe "create_account with invitation system enabled" do
    setup do
      Invitations.enable()
      on_exit(fn -> Invitations.disable() end)
    end

    test "requires a valid invitation token" do
      assert Accounts.create_account(%{}, nil) == {:error, "invalid_invitation_token"}
      assert Accounts.create_account(%{}, "") == {:error, "invalid_invitation_token"}
      assert Accounts.create_account(%{}, "zzzzz") == {:error, "invalid_invitation_token"}
    end
  end

  describe "create_account without invitation system (default)" do
    test "if a valid user is given" do
      invit = insert(:invitation_request)
      user_params = build_user_params()
      {:ok, created} = Accounts.create_account(user_params, invit.token)
      assert user_params.username == created.username
      assert user_params.email == created.email
    end

    test "with auto-generated username only if explicitly requested" do
      invit = insert(:invitation_request)
      user_params = Map.delete(build_user_params(), :username)

      # Without username, no allow_empty_username
      {:error, %Ecto.Changeset{}} = Accounts.create_account(user_params, invit.token)
      # With empty username, no allow_empty_username
      {:error, %Ecto.Changeset{}} =
        Accounts.create_account(Map.put(user_params, :username, ""), invit.token)

      # Without username, allow_empty_username
      {:ok, created} =
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

    test "truncate name if too long" do
      user_params = Map.put(build_user_params(), :name, "abcdefghijklmnopqrstuvwxyz")
      provider_params = %{fb_user_id: "4242424242"}
      {:ok, user} = Accounts.create_account(user_params, nil, provider_params: provider_params)
      assert user.name == "abcdefghijklmnopqrst"
    end

    test "delete invitation request after creating the user" do
      Repo.delete_all(DB.Schema.InvitationRequest)
      invit = insert(:invitation_request)
      user_params = build_user_params()
      Accounts.create_account(user_params, invit.token)
      assert Repo.get(DB.Schema.InvitationRequest, invit.id) == nil
    end

    test "sends an email to welcome the user" do
      invit = insert(:invitation_request)
      user_params = build_user_params()
      {:ok, user} = Accounts.create_account(user_params, invit.token)
      assert_delivered_email(CF.Mailer.Email.welcome(user))
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
      Reputation.update()
      updated_user = Repo.get(DB.Schema.User, user.id)

      assert updated_user.email_confirmed
      assert updated_user.email_confirmation_token == nil
      assert user.reputation < updated_user.reputation
    end
  end

  describe "achievements" do
    test "unlock achievements" do
      user = insert(:user)
      achievement = DB.Type.Achievement.get(:bulletproof)
      Accounts.unlock_achievement(user, achievement)
      updated = Repo.get(DB.Schema.User, user.id)
      assert achievement in updated.achievements
    end
  end

  test "link speaker" do
    user = insert(:user, speaker: nil)
    speaker = insert(:speaker)
    {:ok, updated_user} = Accounts.link_speaker(user, speaker)
    assert updated_user.speaker_id == speaker.id
  end

  describe "complete_onboarding_step/2" do
    test "it returns {:ok, %User{}} when success" do
      user =
        :user
        |> insert(completed_onboarding_steps: [])
        |> Accounts.complete_onboarding_step(2)

      assert {:ok, %User{}} = user
    end

    test "user returned has right onboarding steps" do
      user =
        :user
        |> insert(completed_onboarding_steps: [])
        |> Accounts.complete_onboarding_step(2)

      assert {:ok, %User{completed_onboarding_steps: [2]}} = user
    end

    test "it fails with an error tuple" do
      error =
        :user
        |> insert(completed_onboarding_steps: [])
        |> Accounts.complete_onboarding_step(72)

      assert Result.error?(error)
    end
  end

  describe "complete_onboarding_steps/2" do
    test "it returns {:ok, %User{}} when success" do
      user =
        :user
        |> insert(completed_onboarding_steps: [])
        |> Accounts.complete_onboarding_steps([1, 2])

      assert {:ok, %User{}} = user
    end

    test "user returned has right onboarding steps" do
      user =
        :user
        |> insert(completed_onboarding_steps: [])
        |> Accounts.complete_onboarding_steps([1, 2])

      assert {:ok, %User{completed_onboarding_steps: [1, 2]}} = user
    end

    test "it fails with an error tuple" do
      error =
        :user
        |> insert(completed_onboarding_steps: [])
        |> Accounts.complete_onboarding_steps([1, 72])

      assert Result.error?(error)
    end
  end

  describe "delete account" do
    test "nilify all user's comments" do
      user = insert(:user)
      comments = insert_list(3, :comment, user: user)
      Accounts.delete_account(user)

      for comment <- comments do
        comment = Repo.get(DB.Schema.Comment, comment.id)
        assert not is_nil(comment), "User's comment should not be deleted"
        assert comment.user_id == nil, "Comment should be anonymized"
      end
    end
  end
end
