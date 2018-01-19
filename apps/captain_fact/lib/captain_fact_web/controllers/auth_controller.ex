defmodule UeberauthWithRedirectUriFixer do
  @moduledoc """
  Same as Ueberauth plug, but fixes OAuth redirect URI
  """
  
  def init(_) do
    Ueberauth.init()
  end

  @fb_auth_callback "/auth/facebook/callback"

  def call(conn = %{request_path: request_path, params: params}, opts) do
    ueberauth_opts =
      if request_path == @fb_auth_callback do
        frontend_url = Application.get_env(:captain_fact, :frontend_url)
        fixed_url = if Map.has_key?(params, "invitation_token"),
          do: "#{frontend_url}/login/callback/facebook?invitation_token=#{params["invitation_token"]}",
          else: "#{frontend_url}/login/callback/facebook"

        Map.update!(opts, @fb_auth_callback, fn {module, :run_callback, callback_opts} ->
          {module, :run_callback, Map.put(callback_opts, :callback_url, fixed_url)}
        end)
      else
        opts
      end
    Ueberauth.call(conn, ueberauth_opts)
  end
end

defmodule CaptainFactWeb.AuthController do
  @moduledoc"""
  Auth controller. Deal with user sign_in, logout and interactions with Ueberauth
  """

  use CaptainFactWeb, :controller
  require Logger

  alias CaptainFact.Accounts
  alias CaptainFact.Accounts.{User, Authenticator}
  alias CaptainFactWeb.{ErrorView, UserView, AuthController }

  plug UeberauthWithRedirectUriFixer
  plug Guardian.Plug.EnsureAuthenticated, [handler: AuthController] when action in [:logout, :unlink_provider]


  @err_authentication_failed "authentication_failed"
  @err_invalid_email_password "invalid_email_password"


  @doc """
  Called when auth fails
  """
  def callback(%{assigns: %{ueberauth_failure: f}} = conn, _params) do
    Logger.debug(fn -> inspect(f)  end)
    conn
    |> put_status(:bad_request)
    |> render(ErrorView, "error.json", message: @err_authentication_failed)
  end


  @doc"""
  Auth with identity (email + password)
  """
  def callback(%{assigns: %{ueberauth_auth: auth = %{provider: :identity}}} = conn, _params) do
    result = with {:ok, user} <- user_from_auth(auth),
                  :ok <- Authenticator.validate_pass(user.encrypted_password, auth.credentials.other.password),
                  do: signin_user(conn, user)

    case result do
      {:error, _} ->
        conn
        |> put_status(:unauthorized)
        |> render(ErrorView, "error.json", message: @err_invalid_email_password)
      response ->
        response
    end
  end

  @doc"""
  Auth with third party provider (OAuth)
  """
  def callback(conn = %{assigns: %{ueberauth_auth: auth}}, params) do
    case Guardian.Plug.current_resource(conn) do
      nil -> third_party_signin_unauthenticated(conn, Map.get(params, "invitation_token"))
      user -> signin_user(conn, Authenticator.link_provider!(user, provider_specific_infos(auth)))
    end
  end

  @doc"""
  Unlink given provider from user's account
  """
  def unlink_provider(conn, %{"provider" => "facebook"}) do
    updated_user = Authenticator.unlink_provider!(Guardian.Plug.current_resource(conn), :facebook)
    render(conn, UserView, :show, user: updated_user)
  end

  @doc"""
  Logout user. TODO: invalidate token (must use ecto)
  """
  def logout(conn, _params) do
    conn
    |> Guardian.Plug.current_token
    |> Guardian.revoke!
    send_resp(conn, 204, "")
  end

  # Guardian methods: render errors on unauthenticated / unauthorized

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

  # ---- Private ----

  defp third_party_signin_unauthenticated(%{assigns: %{ueberauth_auth: auth}} = conn, invitation_token) do
    case user_from_auth(auth) do
      # A user with this email already exists, link third party to email
      {:ok, user} ->
        signin_user(conn, Authenticator.link_provider!(user, provider_specific_infos(auth)))
      # User doesn't exist, create account
      {:error, _} ->
        case Accounts.create_account(auth_info_to_user_info(auth), invitation_token, [
          provider_params: provider_specific_infos(auth),
          allow_empty_username: true
        ]) do
          {:ok, user} -> signin_user(conn, user)
          {:error, error} ->
            conn
            |> put_status(:bad_request)
            |> render(ErrorView, "error.json", message: error)
        end
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
      %{"is_silhouette" => true} ->
        infos
      _ ->
        picture_url =
          auth.info.image
          |> String.replace(~r/^http:\/\//, "https://")
          |> String.replace(~r/\?type=square/, "?type=normal")

        Map.merge(infos, %{picture_url: picture_url})
    end
  end
  defp provider_specific_infos(_), do: %{}

  defp user_from_auth(auth = %{provider: :facebook}) do
    case Authenticator.get_user_by_third_party(auth.provider, auth.uid, auth.info.email) do
      nil -> {:error, %{"email" => ["invalid_email"]}}
      user -> {:ok, user}
    end
  end
  defp user_from_auth(auth) do
    case Repo.get_by(User, email: auth.info.email) do
      nil -> {:error, %{"email" => ["invalid_email"]}}
      user -> {:ok, user}
    end
  end

  # [!] Must be called once all verifications (password, third party...) have been done
  # Render a user_with token %{user, token}
  defp signin_user(conn, user) do
    conn
    |> Guardian.Plug.api_sign_in(user)
    |> Guardian.Plug.current_token
    |> case do
         nil ->
           conn
           |> put_status(:bad_request)
           |> render(ErrorView, "error.json", message: @err_authentication_failed)
         token ->
           render(conn, UserView, "user_with_token.json", %{user: user, token: token})
       end
  end
end