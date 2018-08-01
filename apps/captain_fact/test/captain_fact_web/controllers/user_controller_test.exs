defmodule CaptainFactWeb.UserControllerTest do
  use CaptainFactWeb.ConnCase
  import DB.Factory
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias DB.Schema.UserAction
  alias DB.Schema.Comment
  alias DB.Schema.ResetPasswordRequest

  alias CaptainFact.Accounts.Invitations
  alias CaptainFact.Authenticator.GuardianImpl

  describe "Get user" do
    test "displays sensitive info (email...) when requesting /me" do
      user = insert(:user)

      returned_user =
        user
        |> build_authenticated_conn()
        |> get("/users/me")
        |> json_response(:ok)

      assert Map.has_key?(returned_user, "email")
    end

    test "displays limited info if someone else" do
      requesting_user = insert(:user)
      requested_user = insert(:user)

      returned_user =
        requesting_user
        |> build_authenticated_conn()
        |> get("/users/username/#{requested_user.username}")
        |> json_response(:ok)

      refute Map.has_key?(returned_user, "email")
    end
  end

  describe "create account" do
    test "must work if joined a valid invitation" do
      invit = insert(:invitation_request)

      user =
        build(:user)
        |> Map.take([:email, :username])
        |> Map.put(:password, "dsad888-!")

      response =
        build_conn()
        |> post("/users", %{user: user, invitation_token: invit.token})
        |> json_response(:created)

      {:ok, _claims} = GuardianImpl.decode_and_verify(response["token"])
    end

    test "must not work without an invitation if invitation system is enabled" do
      Invitations.enable()
      on_exit(fn -> Invitations.disable() end)

      user =
        build(:user)
        |> Map.take([:email, :username])
        |> Map.put(:password, "dsad888-!")

      response =
        build_conn()
        |> post("/users", %{user: user})
        |> json_response(:bad_request)

      assert response == %{"error" => "invalid_invitation_token"}
    end
  end

  describe "reset password" do
    test "full flow" do
      user = insert(:user)
      new_password = "Passw0rDChanged...=)"

      # Ask for password reset
      build_conn()
      |> post("/users/reset_password/request", %{email: user.email})
      |> response(204)

      # Verify token
      req = Repo.get_by!(ResetPasswordRequest, user_id: user.id)

      resp =
        build_conn()
        |> get("/users/reset_password/verify/#{req.token}")
        |> json_response(200)

      assert Map.has_key?(resp, "username")

      # Confirm (change password)
      resp =
        build_conn()
        |> post("/users/reset_password/confirm", %{
          token: req.token,
          password: new_password
        })
        |> json_response(200)

      assert Map.has_key?(resp, "email")
    end

    test "should not inform user if email doesn't exists" do
      build_conn()
      |> post("/users/reset_password/request", %{email: "total_bullshit!"})
      |> response(204)
    end
  end

  describe "unlock achievement" do
    @bulletproof_achievement DB.Type.Achievement.get(:bulletproof)
    @help_achievement DB.Type.Achievement.get(:help)
    @allowed_achievements [@bulletproof_achievement, @help_achievement]

    test "work for bulletproof / help" do
      achievement = Enum.random(@allowed_achievements)

      updated_achievements =
        :user
        |> insert()
        |> build_authenticated_conn()
        |> put("/users/me/achievements/#{achievement}")
        |> json_response(200)
        |> Map.get("achievements")

      assert achievement in updated_achievements
    end

    test "returns 400 for all the other achievements and invalids" do
      forbidden = Enum.into(1..20, []) -- @allowed_achievements
      user = insert(:user)

      for achievement <- forbidden do
        user
        |> build_authenticated_conn()
        |> put("/users/me/achievements/#{achievement}")
        |> response(400)
      end
    end
  end

  describe "invitations" do
    test "should say ok everytime the user request with valid info" do
      email = "test@email.fr"
      response(request_invite(email), 204)
      response(request_invite(email), 204)
    end

    test "should inform the user if email is not valid" do
      assert json_response(request_invite("xxx"), 400) == %{"error" => "invalid_email"}

      assert json_response(request_invite("toto@yopmail.fr"), 400) == %{
               "error" => "invalid_email"
             }

      assert json_response(request_invite("x@xx"), 400) == %{"error" => "invalid_email"}
    end

    defp request_invite(email) do
      build_conn()
      |> post("/users/request_invitation", %{email: email})
    end
  end

  describe "delete account" do
    test "when deleting its account, all comments and user actions are deleted too" do
      user = insert(:user)
      Enum.map(insert_list(10, :comment, %{user: user}), &with_action/1)
      insert_list(10, :user_action, %{user: user})

      assert Enum.count(Repo.all(where(UserAction, [a], a.user_id == ^user.id))) != 0
      assert Enum.count(Repo.all(where(Comment, [c], c.user_id == ^user.id))) != 0

      user
      |> build_authenticated_conn()
      |> delete("/users/me")
      |> response(204)

      assert Enum.empty?(Repo.all(where(UserAction, [a], a.user_id == ^user.id)))
      assert Enum.empty?(Repo.all(where(Comment, [c], c.user_id == ^user.id)))
    end
  end

  describe "newsletter" do
    test "unsubscribe with invalid token returns an error" do
      user = insert(:user)
      assert user.newsletter == true

      build_conn()
      |> get("/newsletter/unsubscribe/NotAValidToken")
      |> response(:bad_request)
    end

    test "unsubscribe with a valid token returns 204" do
      user = insert(:user)
      assert user.newsletter == true

      build_conn()
      |> get("/newsletter/unsubscribe/#{user.newsletter_subscription_token}")
      |> response(204)

      assert Repo.get(User, user.id).newsletter == false

      # Return ok even if already unsubscribed
      build_conn()
      |> get("/newsletter/unsubscribe/#{user.newsletter_subscription_token}")
      |> response(204)
    end
  end

  test "confirm email" do
    user = insert(:user)
    refute user.email_confirmed

    # No need to be authenticated to validate email
    build_conn()
    |> put("/users/me/confirm_email/#{user.email_confirmation_token}")
    |> response(:no_content)

    assert Repo.get(User, user.id).email_confirmed
  end

  test "confirm email with bad token returns 404" do
    # No need to be authenticated to validate email
    build_conn()
    |> put("/users/me/confirm_email/-----TotallyBullshitToken-----")
    |> response(:not_found)
  end

  test "GET /users/me/available_flags" do
    user = build(:user) |> Map.put(:reputation, 4200) |> insert()

    available =
      user
      |> build_authenticated_conn()
      |> get("/users/me/available_flags")
      |> json_response(:ok)
      |> Map.get("flags_available")

    assert is_number(available) and available > 0
  end

  test "must be authenticated to update, delete and available_flags" do
    response(get(build_conn(), "/users/me"), 401) =~ "unauthorized"
    response(put(build_conn(), "/users/me"), 401) =~ "unauthorized"
    response(get(build_conn(), "/users/me/available_flags"), 401) =~ "unauthorized"
    response(delete(build_conn(), "/users/me"), 401) =~ "unauthorized"
  end

  describe "post complete_onboarding_step" do
    test "returns 200 for valid value" do
      :user
      |> insert
      |> build_authenticated_conn
      |> post("users/me/onboarding/complete_step", %{step: 12})
      |> json_response(:ok)
    end

    test "returns 422 for unvalid value" do
      :user
      |> insert()
      |> build_authenticated_conn
      |> post("users/me/onboarding/complete_step", %{step: 72})
      |> json_response(:unprocessable_entity)
    end
  end

  describe "post complete_onboarding_steps" do
    test "returns 200 for valid value" do
      :user
      |> insert
      |> build_authenticated_conn
      |> post("users/me/onboarding/complete_steps", %{steps: [1, 3, 5]})
      |> json_response(:ok)
    end

    test "returns 422 for unvalid value" do
      :user
      |> insert
      |> build_authenticated_conn
      |> post("users/me/onboarding/complete_steps", %{steps: [1, 3, 76]})
      |> json_response(:unprocessable_entity)
    end
  end

  describe "delete onboarding" do
    test "returns 200" do
      :user
      |> insert(completed_onboarding_steps: [1, 2])
      |> build_authenticated_conn
      |> delete("/users/me/onboarding")
      |> json_response(:ok)
    end
  end
end
