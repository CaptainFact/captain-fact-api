defmodule CaptainFact.Web.AuthController do
  use CaptainFact.Web, :controller
  require Logger

  alias Ecto.Multi
  alias CaptainFact.UsernameGenerator
  alias CaptainFact.Web.{ErrorView, UserView, User, AuthController }

  plug Ueberauth
  plug Guardian.Plug.EnsureAuthenticated, [handler: AuthController] when action in [:delete, :me]


  @err_authentication_failed "authentication_failed"
  @err_invalid_email_password "invalid_email_password"


  # If auth fails
  def callback(%{assigns: %{ueberauth_failure: f}} = conn, _params) do
    Logger.debug(inspect(f))
    conn
    |> put_status(:bad_request)
    |> render(ErrorView, "error.json", message: @err_authentication_failed)
  end

  # Only used by admin
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"type" => "session"}) do
    conn = Plug.Conn.fetch_session(conn)
    result = with {:ok, user} <- user_from_auth(auth),
              :ok <- validate_pass(user.encrypted_password, auth.credentials.other.password),
              do: Guardian.Plug.sign_in(conn, user)
    case result do
      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> render(ErrorView, "error.json", message: @err_invalid_email_password)
      _ ->
        redirect(result, to: "/jouge42")
    end
  end

  # Special case for identity
  def callback(%{assigns: %{ueberauth_auth: auth = %{provider: :identity}}} = conn, _params) do
    result = with {:ok, user} <- user_from_auth(auth),
                  :ok <- validate_pass(user.encrypted_password, auth.credentials.other.password),
                  do: signin_user(conn, user)
    case result do
      {:ok, user, token} ->
        render(conn, UserView, "show.json", user: user, token: token)
      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> render(ErrorView, "error.json", message: @err_invalid_email_password)
    end
  end

  # For all others (OAuth) - create if doesn't exists, link otherwise
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user = case user_from_auth(auth) do
      {:ok, user} -> user # TODO Store FB / Twitter / G+ (...) id
      {:error, _} -> create_user_from_oauth!(auth)
    end

    case signin_user(conn, user) do
      {:ok, user, token} ->
        render(conn, UserView, "show.json", user: user, token: token)
      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> render(ErrorView, "error.json", message: @err_authentication_failed)
    end
  end

  defp create_user_from_oauth!(auth) do
    Multi.new
    |> Multi.insert(:base_user, User.registration_changeset(
        %User{username: "temporary-#{temporary_username(auth.info.email)}"},
        %{
           name: auth.info.name,
           email: auth.info.email,
           password: NotQwerty123.RandomPassword.gen_password()
           # TODO Image
           # TODO Social networks ids
         })
       )
    |> Multi.run(:final_user, fn %{base_user: user} ->
        User.changeset(user, %{})
        |> Ecto.Changeset.put_change(:username, UsernameGenerator.generate(user.id))
        |> Repo.update()
     end)
    |> Repo.transaction()
    |> case do
        {:ok, %{final_user: user}} -> user
    end
  end

  defp temporary_username(email) do
    :crypto.hash(:sha256, email)
    |> Base.encode64
    |> String.slice(-8..-2)
  end

  defp user_from_auth(auth) do
    result = Repo.get_by(User, email: auth.info.email)
    case result do
      nil -> {:error, %{"email" => ["Invalid email"]}}
      user -> {:ok, user}
    end
  end

  defp validate_pass(_encrypted, password) when password in [nil, ""] do
    {:error, "password required"}
  end

  defp validate_pass(encrypted, password) do
    if Comeonin.Bcrypt.checkpw(password, encrypted) do
      :ok
    else
      {:error, "invalid password"}
    end
  end

  defp signin_user(conn, user) do
    token =
      conn
      |> Guardian.Plug.api_sign_in(user)
      |> Guardian.Plug.current_token
    {:ok, user, token}
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, UserView, "show.json", user: user)
  end

  def delete(conn, _params) do
    conn
      |> Guardian.Plug.current_token
      |> Guardian.revoke!

    send_resp(conn, 204, "")
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(:unauthorized)
    |> render(ErrorView, "error.json")
  end

  def unauthorized(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> render(ErrorView, "error.json")
  end
end
