defmodule CaptainFactWeb.AuthControllerTest do
  use CaptainFactWeb.ConnCase
  import CaptainFact.Factory

  alias CaptainFact.Accounts.User
  alias CaptainFact.Repo

  @facebook_default_picture "http://graph.facebook.com/10154431272431347/picture?width=96&height=96"

  describe "identity" do
    test "can login with the good email / password combination" do
      auth_path = "/api/auth/identity/callback"
      password = "nic€P@ssword!"
      user = insert_user_with_custom_password(password)

      # Invalid password
      build_conn()
      |> post(auth_path, email: user.email, password: "Invalid!")
      |> json_response(:unauthorized)

      # Valid password
      response =
        build_conn()
        |> post(auth_path, email: user.email, password: password)
        |> json_response(:ok)

      Guardian.decode_and_verify!(response["token"])
    end
  end

  describe "facebook auth" do
    test "can login" do
      user = insert(:user)
      auth = %{ueberauth_auth: build_auth(:facebook, user.fb_user_id, user.email, user.name)}
      response =
        build_conn()
        |> Map.put(:assigns, auth)
        |> post("/api/auth/facebook/callback")
        |> json_response(:ok)

      assert response["user"]["id"] == user.id, "should use existing account if exists"
    end

    test "link profile if same email" do
      user =
        build(:user)
        |> Map.put(:fb_user_id, nil)
        |> insert()

      auth = %{ueberauth_auth: build_auth(:facebook, "42424242", user.email)}
      response =
        build_conn()
        |> Map.put(:assigns, auth)
        |> post("/api/auth/facebook/callback")
        |> json_response(:ok)

      assert response["user"]["id"] == user.id, "should use existing account if email exists"
    end

    test "show an error if not invited" do
      user = build(:user)
      auth = %{ueberauth_auth: build_auth(:facebook, user.fb_user_id, user.email, user.name)}
      response =
        build_conn()
        |> Map.put(:assigns, auth)
        |> post("/api/auth/facebook/callback")
        |> json_response(:bad_request)

      assert response == %{"error" => "invalid_invitation_token"}
    end

    test "create account if it doesn't exist" do
      invit = insert(:invitation_request)
      user = build(:user)
      auth = %{ueberauth_auth: build_auth(:facebook, user.fb_user_id, user.email, user.name)}
      response =
        build_conn()
        |> Map.put(:assigns, auth)
        |> post("/api/auth/facebook/callback", %{invitation_token: invit.token})
        |> json_response(:ok)

      Guardian.decode_and_verify!(response["token"])
    end

    test "if user changed its email and has 2 accounts, always prefer facebook auth account" do
      nb_accounts_before = Repo.aggregate(User, :count, :id)
      nb_to_create = 10
      # User creates 5 accounts via email
      user_emails = insert_list(div(nb_to_create, 2), :user, %{fb_user_id: nil})
      # User create an account using facebook with a new, unused email
      user_facebook = insert(:user)
      # And create again 4 accounts via email
      user_emails = user_emails ++ insert_list(div(nb_to_create, 2) - 1, :user, %{fb_user_id: nil})

      # User changes its email on FB using existing emails and try to login...
      for user <- user_emails do
        auth = %{ueberauth_auth: build_auth(:facebook, user_facebook.fb_user_id, user.email)}
        response =
          build_conn()
          |> Map.put(:assigns, auth)
          |> post("/api/auth/facebook/callback")
          |> json_response(:ok)

        Guardian.decode_and_verify!(response["token"])
        assert response["user"]["id"] == user_facebook.id, "should always preferer facebook uid over email"
        assert Repo.aggregate(User, :count, :id) == nb_accounts_before + nb_to_create
      end
    end
  end

  describe "admin" do
    test "can login and is redirected to /jouge42" do
      reset_users_table()

      password = "kikiTotoX"
      user = insert_user_with_custom_password(password)
      response =
        build_conn()
        |> post("/api/auth/identity/callback", %{
             "type" => "session",
             "email" => user.email,
             "password" => password
           })

      assert redirected_to(response, 302) =~ "/jouge42"
      # TODO Check session
    end

    test "cannot login with invalid credentials" do
      reset_users_table()

      user = insert_user_with_custom_password("kikiTotoX")
      build_conn()
      |> post("/api/auth/identity/callback", %{
           "type" => "session",
           "email" => user.email,
           "password" => "NotTheOriginalPassword"
         })
      |> response(401)
    end

    test "can only be the user with id 1" do
      reset_users_table()

      insert(:user)
      password = "FakeAdmin"
      user = insert_user_with_custom_password(password)
      assert Repo.aggregate(User, :count, :id) == 2, "there should be only 2 users"
      assert user.id != 1

      build_conn()
      |> post("/api/auth/identity/callback", %{
           "type" => "session",
           "email" => user.email,
           "password" => password
         })
      |> response(401)
    end
  end

  describe "reset password" do
    test "full flow" do
      user = insert(:user)
      new_password = "Passw0rDChanged...=)"

      # Ask for password reset
      build_conn()
      |> post("/api/auth/reset_password/request", %{email: user.email})
      |> response(204)

      # Verify token
      req = Repo.get_by!(CaptainFact.Accounts.ResetPasswordRequest, user_id: user.id)
      resp =
        get(build_conn(), "/api/auth/reset_password/verify/#{req.token}")
        |> json_response(200)
      assert Map.has_key?(resp, "username")

      # Confirm (change password)
      resp =
        build_conn()
        |> post("/api/auth/reset_password/confirm", %{
             token: req.token,
             password: new_password
           })
        |> json_response(200)
      assert Map.has_key?(resp, "email")
    end

    test "should not inform user if email doesn't exists" do
        build_conn()
        |> post("/api/auth/reset_password/request", %{email: "total_bullshit!"})
        |> response(204)
      end
  end

  describe "invitations" do
    test "should say ok everytime the user request with valid info" do
      email = "test@email.fr"
      request_invite(email) |> response(204)
      request_invite(email) |> response(204)
    end

    test "should inform the user if email is not valid" do
      assert json_response(request_invite("xxx"), 400) == %{"error" => "invalid_email"}
      assert json_response(request_invite("toto@yopmail.fr"), 400) == %{"error" => "invalid_email"}
      assert json_response(request_invite("x@xx"), 400) == %{"error" => "invalid_email"}
    end

    defp request_invite(email) do
      build_conn()
      |> post("/api/auth/request_invitation", %{email: email})
    end
  end

  defp reset_users_table() do
    Repo.delete_all(User)
    query = "ALTER SEQUENCE users_id_seq RESTART WITH 1"
    Ecto.Adapters.SQL.query!(Repo, query, [])
  end

  defp insert_user_with_custom_password(password) do
    insert(:user, %{encrypted_password: Comeonin.Bcrypt.hashpwsalt(password)})
  end

  defp build_auth(provider, uid, email, name \\ "Any name") do
    %{
      provider: provider,
      uid: uid,
      info: %{
        name: name,
        email: email,
        image: @facebook_default_picture
      }
    }
    |> provider_specific_auth_infos
  end

  defp provider_specific_auth_infos(auth = %{provider: :facebook}) do
    Map.merge(auth, %{
      extra: %{
        raw_info: %{
          user: %{
            "picture" => %{
              "data" => %{
                "is_silhouette" => false
              }
            }
          }
        }
      }
    })
  end
  defp provider_specific_auth_infos(auth), do: auth
end