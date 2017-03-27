defmodule CaptainFact.VideoController do
  use CaptainFact.Web, :controller
  alias CaptainFact.Video

  plug Guardian.Plug.EnsureAuthenticated, [handler: CaptainFact.AuthController]
       when action in [:create, :update, :delete]

  def index(conn, %{"user_id" => user_id}) do
    connected_user = Guardian.Plug.current_resource(conn)
    query = Video
      |> Video.with_speakers
      |> where([v], v.owner_id  == ^user_id)
      |> order_by([v], desc: v.id)

    query = if !connected_user || connected_user.id !== String.to_integer(user_id) do
      query |> where([v], v.is_private == false)
    else
      query
    end

    videos = Repo.all(query)
    render(conn, "index.json", videos: videos)
  end

  def index(conn, _params) do
    # TODO Pagination
    videos = Video
    |> Video.with_speakers
    |> where([v], v.is_private == false)
    |> order_by([v], desc: v.id)
    |> Repo.all()
    render(conn, "index.json", videos: videos)
  end

  def create(conn, video_params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = Video.changeset(%Video{owner_id: user.id}, video_params)
    case Repo.insert(changeset) do
      {:ok, video} ->
        video = %{video | speakers: []}
        render(conn, "show.json", video: video)
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
    send_resp(conn, :ok, "")
  end

  def update(conn, params = %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    video = Repo.get!(user_videos(user), id)
    changeset = Video.changeset(video, params)
    case Repo.update(changeset) do
      {:ok, video} -> render(conn, "show_simple.json", video: video)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
