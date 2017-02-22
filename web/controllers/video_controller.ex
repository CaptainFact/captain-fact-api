defmodule CaptainFact.VideoController do
  use CaptainFact.Web, :controller
  alias CaptainFact.Video

  plug Guardian.Plug.EnsureAuthenticated, [handler: CaptainFact.AuthController]
       when action in [:create, :index, :update, :delete]

  def index(conn, %{"user_id" => user_id}) do
    videos = Video
      |> Video.with_speakers
      |> where([v], v.owner_id  == ^user_id)
      |> order_by([v], desc: v.id)
      |> Repo.all
    render(conn, "index.json", videos: videos)
  end

  def index(conn, _params) do
    videos = Video |> order_by([v], desc: v.id) |> Repo.all()
    render(conn, "index.json", videos: videos)
  end

  def show(conn, %{"id" => id}) do
    # IDEA: Use video title instead of id
    video = Repo.get!(Video.with_speakers(Video), id)
    render(conn, "show.json", video: video)
  end

  def create(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = Video.changeset(%Video{owner_id: user.id}, params)
    case Repo.insert(changeset) do
      {:ok, video} -> render(conn, "show.json", video: video)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp user_videos(user) do
    assoc(user, :videos)
  end

  def delete(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    video = Repo.get!(user_videos(user), id)
    Repo.delete!(video)
    render(conn, "show.json", video: video)
  end

  def update(conn, params = %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    video = Repo.get!(user_videos(user), id)
    changeset = Video.changeset(video, params)
    case Repo.update(changeset) do
      {:ok, video} -> render(conn, "show.json", video: video)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
