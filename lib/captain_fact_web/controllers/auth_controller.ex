defmodule CaptainFactWeb.AuthController do
  use CaptainFactWeb, :controller
  require Logger

  alias Ecto.Multi
  alias CaptainFact.Accounts
  alias CaptainFact.Accounts.{User, UsernameGenerator}
  alias CaptainFactWeb.{ErrorView, UserView, AuthController }

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

  # Only used for admin auth
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"type" => "session"}) do
    conn = Plug.Conn.fetch_session(conn)
    result = with {:ok, user = %User{id: 1}} <- user_from_auth(auth),
              :ok <- validate_pass(user.encrypted_password, auth.credentials.other.password),
              do: Guardian.Plug.sign_in(conn, user)

    case result do
      %Plug.Conn{} ->
        redirect(result, to: "/jouge42")
      _ ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "error.json", message: @err_invalid_email_password)
    end
  end

  # Special case for identity
  def callback(%{assigns: %{ueberauth_auth: auth = %{provider: :identity}}} = conn, _params) do
    result = with {:ok, user} <- user_from_auth(auth),
                  :ok <- validate_pass(user.encrypted_password, auth.credentials.other.password),
                  do: signin_user(conn, user)
    case result do
      {:ok, user, token} ->
        render(conn, UserView, "user_with_token.json", %{user: user, token: token})
      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "error.json", message: @err_invalid_email_password)
    end
  end

  # For all others (OAuth) - create if doesn't exists, link otherwise
  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user = case user_from_auth(auth) do
      {:ok, user} ->
        # Try to update user with social network id if needed
        with %{fb_user_id: nil} <- user,
             changeset <- User.oauth_changeset(user, provider_specific_infos(auth)),
             {:ok, newUser} <- Repo.update(changeset) do
          newUser
        else
          _ -> user # Not a big deal if this fails, just return the user
        end
      {:error, _} -> create_user_from_oauth!(auth)
    end

    case signin_user(conn, user) do
      {:ok, user, token} ->
        render(conn, UserView, "user_with_token.json", %{user: user, token: token})
      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> render(ErrorView, "error.json", message: @err_authentication_failed)
    end
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    render(conn, UserView, :show, user: user)
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
    |> render(ErrorView, "401.json")
  end

  def unauthorized(conn, _params) do
    conn
    |> put_status(:forbidden)
    |> render(ErrorView, "403.json")
  end

  # ---- Reset password ----

  def reset_password_request(conn, %{"email" => email}) do
    try do
      Accounts.reset_password!(email, Enum.join(Tuple.to_list(conn.remote_ip), ","))
    rescue
      _ in Ecto.NoResultsError -> "I won't tell the user ;)'"
    end
    send_resp(conn, :no_content, "")
  end

  def reset_password_verify(conn, %{"token" => token}) do
    user = Accounts.check_reset_password_token!(token)
    render(conn, UserView, :show, %{user: user})
  end

  def reset_password_confirm(conn, %{"token" => token, "password" => password}) do
    user = Accounts.confirm_password_reset!(token, password)
    render(conn, UserView, :show, %{user: user})
  end

  # ---- Invitations ----

  def request_invitation(conn, %{"email" => email}) do
    case Accounts.request_invitation(email, Guardian.Plug.current_resource(conn)) do
      {:ok, _} ->
        send_resp(conn, :no_content, "")
      {:error, "invalid_email"} ->
        put_status(conn, :bad_request)
        |> json(%{error: "invalid_email"})
      {:error, _} ->
        send_resp(conn, :bad_request, "")
    end
  end

  # ---- Private ----

  defp create_user_from_oauth!(auth) do
    Multi.new
    |> Multi.insert(:base_user,
         %User{username: temporary_username(auth.info.email)}
         |> User.registration_changeset(auth_info_to_user_info(auth))
         |> User.oauth_changeset(provider_specific_infos(auth))
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

  defp auth_info_to_user_info(auth) do
    %{
       name: auth.info.name,
       email: auth.info.email,
       password: NotQwerty123.RandomPassword.gen_password()
    }
  end

  defp provider_specific_infos(auth = %{provider: :facebook}) do
    infos = %{fb_user_id: auth.uid}
    case auth.extra.raw_info.user["picture"]["data"] do
      %{"is_silhouette" => true} -> infos
      _ -> Map.merge(infos, %{picture_url: auth.info.image})
    end
  end
  defp provider_specific_infos(_), do: %{}

  defp temporary_username(email) do
    :crypto.hash(:sha256, email)
    |> Base.encode64
    |> String.slice(-8..-2)
    |> (fn res -> "temporary-#{res}" end).()
  end

  defp user_from_auth(auth = %{provider: :facebook}) do
    User
    |> where([u], u.fb_user_id == ^auth.uid)
    |> or_where([u], u.email == ^auth.info.email)
    |> Repo.all()
    |> Enum.reduce(nil, fn (user, best_fit) ->
         # User may link a facebook account, change its facebook email and re-connect with facebook
         # so we link by default using the facebook account and if none we try to link with email
         if user.fb_user_id == auth.uid or is_nil(best_fit),
          do: user,
          else: best_fit
       end)
    |> case do
      nil -> {:error, %{"email" => ["Invalid email"]}}
      user -> {:ok, user}
    end
  end
  defp user_from_auth(auth) do
    case Repo.get_by(User, email: auth.info.email) do
      nil -> {:error, %{"email" => ["Invalid email"]}}
      user -> {:ok, user}
    end
  end

  defp validate_pass(_encrypted, password) when password in [nil, ""] do
    {:error, "password_required"}
  end

  defp validate_pass(encrypted, password) do
    if Comeonin.Bcrypt.checkpw(password, encrypted) do
      :ok
    else
      {:error, "invalid_password"}
    end
  end

  defp signin_user(conn, user) do
    token =
      conn
      |> Guardian.Plug.api_sign_in(user)
      |> Guardian.Plug.current_token
    {:ok, user, token}
  end
end
