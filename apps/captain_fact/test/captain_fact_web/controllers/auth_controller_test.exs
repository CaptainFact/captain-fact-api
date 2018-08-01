defmodule CaptainFactWeb.AuthControllerTest do
  use CaptainFactWeb.ConnCase
  import DB.Factory

  alias CaptainFact.Authenticator.GuardianImpl

  @identity_auth_path "/auth/identity/callback"

  describe "identity" do
    test "can login with the good email / password combination" do
      password = "nic€P@ssword!"
      user = insert_user_with_custom_password(password)

      # Invalid password
      build_conn()
      |> post(@identity_auth_path, email: user.email, password: "Invalid!")
      |> json_response(:unauthorized)

      # Valid password
      response =
        build_conn()
        |> post(@identity_auth_path, email: user.email, password: password)
        |> json_response(:ok)

      {:ok, _claims} = GuardianImpl.decode_and_verify(response["token"])
    end

    # TODO Ensure token gets revoked
    #    test "logout revokes token" do
    #      password = "nic€P@ssword!"
    #      user = insert_user_with_custom_password(password)
    #
    #      # Login
    #      first_token =
    #        build_conn()
    #        |> post(@identity_auth_path, email: user.email, password: password)
    #        |> json_response(:ok)
    #        |> Map.get("token")
    #
    #      # Ensure token is valid
    #      {:ok, _} = Guardian.decode_and_verify(first_token)
    #
    #      # Logout
    #      build_conn()
    #      |> Plug.Conn.put_req_header("authorization", "Bearer #{first_token}")
    #      |> delete("/auth", email: user.email, password: password)
    #      |> response(204)
    #
    #      # Refute token validity
    #      {:error, _} = Guardian.decode_and_verify(first_token)
    #
    #      # If making another request, token must be different
    #      second_token =
    #        build_conn()
    #        |> post(@identity_auth_path, email: user.email, password: password)
    #        |> json_response(:ok)
    #        |> Map.get("token")
    #
    #      assert first_token != second_token
    #    end
  end

  defp insert_user_with_custom_password(password) do
    insert(:user, %{encrypted_password: Bcrypt.hash_pwd_salt(password)})
  end
end
