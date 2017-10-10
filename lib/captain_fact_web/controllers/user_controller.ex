defmodule CaptainFactWeb.UserController do
  use CaptainFactWeb, :controller

  alias CaptainFact.Accounts
  alias CaptainFact.Accounts.{User, UserPermissions}

  plug Guardian.Plug.EnsureAuthenticated, [handler: CaptainFactWeb.AuthController]
  when action in [:update, :delete, :available_flags, :show_me]


  def create(conn, params = %{"user" => user_params}) do
    case Accounts.create_account(user_params, Map.get(params, "invitation_token")) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user, :token)
        conn
        |> put_status(:created)
        |> render("user_with_token.json", %{user: user, token: token})
      {:error, changeset = %Ecto.Changeset{}} ->
        conn
        |> put_status(:bad_request)
        |> render(CaptainFactWeb.ChangesetView, "error.json", changeset: changeset)
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> render(CaptainFactWeb.ErrorView, "error.json", %{message: message})
    end
  end

  def show(conn, %{"username" => username}) do
    render(conn, "show_public.json", user: Repo.get_by!(User, username: username))
  end

  def show_me(conn, _params) do
    render(conn, "show.json", user: Guardian.Plug.current_resource(conn))
  end

  def update(conn, params) do
    Guardian.Plug.current_resource(conn)
    |> User.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, user} ->
        render(conn, :show, user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFactWeb.ChangesetView, :error, changeset: changeset)
    end
  end

  def available_flags(conn, _) do
    current_user = Guardian.Plug.current_resource(conn)
    case UserPermissions.check(current_user, :flag, :comment) do
      {:ok, num_available} -> json(conn, %{flags_available: num_available})
      {:error, _reason} ->
        json(conn, %{flags_available: 0})
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    try do
      Accounts.confirm_email!(token)
      send_resp(conn, :no_content, "")
    rescue
      _ -> json(put_status(conn, 404), %{error: "invalid_token"})
    end
  end

  def delete(conn, _params) do
    # TODO Soft delete, do the real delete after 1 week to avaoid user mistakes
    Repo.delete!(Guardian.Plug.current_resource(conn))
    send_resp(conn, :no_content, "")
  end
end
