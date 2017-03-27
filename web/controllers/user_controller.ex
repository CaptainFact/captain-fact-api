defmodule CaptainFact.UserController do
  use CaptainFact.Web, :controller

  alias CaptainFact.User

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)

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
