defmodule CaptainFact.UserController do
  use CaptainFact.Web, :controller

  alias CaptainFact.User

  plug Guardian.Plug.EnsureAuthenticated, [handler: CaptainFact.AuthController]
  when action in [:search]

  def create(conn, %{"user" => user_params}) do
    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user, :token)
        conn
        |> put_status(:created)
        |> render("show.json", user: user, token: token)
      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"username" => username}) do
    current_user = Guardian.Plug.current_resource(conn)
    if (current_user && current_user.username == username) do
      render(conn, "show.json", user: current_user)
    else
      render(conn, "show_public.json", user: Repo.get_by!(User, username: username))
    end
  end

  @max_users_search_results 5
  def search(conn, %{"query_string" => query_string}) do
    current_user = Guardian.Plug.current_resource(conn)
    query_string = query_string
      |> URI.decode()
      |> String.replace(~r/%|\*/, "", global: true)
    query_string = "%#{query_string}%"
    users_query =
      from u in User,
      where: u.id != ^current_user.id,
      where: like(u.username, ^query_string) or like(u.name, ^query_string),
      select: [:id, :username, :name],
      limit: @max_users_search_results

    render(conn, "index_public.json", users: Repo.all(users_query))
  end

  def admin_login(conn, _) do
    render(conn, "admin_login.html")
  end

  #
  # def update(conn, %{"id" => id, "user" => user_params}) do
  #   user = Repo.get!(User, id)
  #   changeset = User.changeset(user, user_params)
  #
  #   case Repo.update(changeset) do
  #     {:ok, user} ->
  #       render(conn, "show.json", user: user)
  #     {:error, changeset} ->
  #       conn
  #       |> put_status(:unprocessable_entity)
  #       |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   user = Repo.get!(User, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(user)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
