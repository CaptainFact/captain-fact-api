defmodule CaptainFact.UserController do
  use CaptainFact.Web, :controller

  alias CaptainFact.User

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"users" => users_params}) do
    changeset = User.changeset(%User{}, users_params)

    case Repo.insert(changeset) do
      {:ok, users} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", user_path(conn, :show, users))
        |> render("show.json", users: users)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    users = Repo.get!(User, id)
    render(conn, "show.json", users: users)
  end

  def update(conn, %{"id" => id, "users" => users_params}) do
    users = Repo.get!(User, id)
    changeset = User.changeset(users, users_params)

    case Repo.update(changeset) do
      {:ok, users} ->
        render(conn, "show.json", users: users)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    users = Repo.get!(User, id)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(users)

    send_resp(conn, :no_content, "")
  end
end
