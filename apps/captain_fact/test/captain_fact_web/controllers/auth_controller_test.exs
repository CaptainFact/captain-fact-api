defmodule CaptainFactWeb.AuthControllerTest do
  use CaptainFactWeb.ConnCase
  import DB.Factory


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

  defp insert_user_with_custom_password(password) do
    insert(:user, %{encrypted_password: Comeonin.Bcrypt.hashpwsalt(password)})
  end
end