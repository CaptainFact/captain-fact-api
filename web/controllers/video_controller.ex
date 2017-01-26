defmodule CaptainFact.VideoController do
  use CaptainFact.Web, :controller
  alias CaptainFact.Video

  def index(conn, _params) do
    #TODO: Paginate
    videos = Repo.all(Video)
    render(conn, "index.json", videos: videos)
  end

  def show(conn, %{"id" => id}) do
    # TODO: Use video title
    video = Repo.get!(Video, id)
    render(conn, "show.json", video: video)
  end

  def create(conn, params) do
    changeset = Video.changeset(%Video{}, params)
    case Repo.insert(changeset) do
      {:ok, video} -> render(conn, "show.json", video: video)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, _params) do
    #TODO
  end

  def update(conn, _params) do
    #TODO
  end
end
