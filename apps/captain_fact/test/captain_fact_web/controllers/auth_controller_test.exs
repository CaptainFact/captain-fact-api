defmodule CaptainFactWeb.AuthControllerTest do
  use CaptainFactWeb.ConnCase
  import DB.Factory

  alias DB.Repo
  alias DB.Type.Achievement
  alias DB.Schema.User

  alias CaptainFactWeb.AuthController

  @facebook_default_picture "http://graph.facebook.com/10154431272431347/picture?width=96&height=96"

  describe "identity" do
    test "can login with the good email / password combination" do
      auth_path = "/auth/identity/callback"
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
        |> AuthController.callback(%{})
        |> json_response(:ok)

      assert response["user"]["id"] == user.id, "should use existing account if exists"
      assert Achievement.get(:social_networks) in response["user"]["achievements"], "should unlock social-network achievement"
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
        |> AuthController.callback(%{})
        |> json_response(:ok)

      assert response["user"]["id"] == user.id, "should use existing account if email exists"
      assert Achievement.get(:social_networks) in response["user"]["achievements"], "should unlock social-network achievement"

      CaptainFact.Jobs.Reputation.update()
      assert Repo.get(User, response["user"]["id"]).reputation > response["user"]["reputation"]
    end

    test "show an error if not invited" do
      user = build(:user)
      auth = %{ueberauth_auth: build_auth(:facebook, user.fb_user_id, user.email, user.name)}
      response =
        build_conn()
        |> Map.put(:assigns, auth)
        |> AuthController.callback(%{})
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
        |> AuthController.callback(%{"invitation_token" => invit.token})
        |> json_response(:ok)

      Guardian.decode_and_verify!(response["token"])
      assert Achievement.get(:social_networks) in response["user"]["achievements"], "should unlock social-network achievement"

      CaptainFact.Jobs.Reputation.update()
      assert Repo.get(User, response["user"]["id"]).reputation > response["user"]["reputation"]
    end

    test "user must accept to share email when authenticathing with third party" do
      invit = insert(:invitation_request)
      user = build(:user)
      auth = %{ueberauth_auth: build_auth(:facebook, user.fb_user_id, nil, user.name)}
      response =
        build_conn()
        |> Map.put(:assigns, auth)
        |> AuthController.callback(%{"invitation_token" => invit.token})
        |> json_response(400)

      assert response == %{"error" => "invalid_email"}
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
          |> AuthController.callback(%{})
          |> json_response(:ok)

        Guardian.decode_and_verify!(response["token"])
        assert response["user"]["id"] == user_facebook.id, "should always preferer facebook uid over email"
        assert Repo.aggregate(User, :count, :id) == nb_accounts_before + nb_to_create
      end
    end
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
      extra: %{ raw_info: %{ user: %{
        "picture" => %{ "data" => %{ "is_silhouette" => false } }
      }}}
    })
  end
  defp provider_specific_auth_infos(auth), do: auth
end