defmodule CaptainFact.VideoController do
  use CaptainFact.Web, :controller

  alias CaptainFact.{Video, VideoAdmin, User, Speaker, VideoSpeaker}
  alias CaptainFact.VideoHashId

  plug Guardian.Plug.EnsureAuthenticated, [handler: CaptainFact.AuthController]
  when action in [:create, :update, :delete, :youtube_title]

  def index(conn, %{"user_id" => user_id}) do
    connected_user = Guardian.Plug.current_resource(conn)
    query = Video
      |> Video.with_speakers
      |> Video.with_admins
      |> where([v], v.owner_id  == ^user_id)
      |> order_by([v], desc: v.id)

    query = if !connected_user || connected_user.id !== String.to_integer(user_id) do
      query |> where([v], v.is_private == false)
    else
      query
    end
    render(conn, :index, videos: Repo.all(query))
  end

  def index(conn, _params) do
    # TODO Pagination
    videos = Video
    |> Video.with_speakers
    |> Video.with_admins
    |> where([v], v.is_private == false)
    |> order_by([v], desc: v.id)
    |> Repo.all()
    render(conn, :index, videos: videos)
  end

  def create(conn, video_params) do
    user = Guardian.Plug.current_resource(conn)
    changeset = Video.changeset(%Video{owner_id: user.id}, video_params)
    case Repo.insert(changeset) do
      {:ok, video} ->
        # TODO : User Ecto.Multi to make all this in one transaction
        video = Map.put(video, :speakers, [])
        video = update_admins(video, video_params)
        render(conn, "show.json", video: video)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, :error, changeset: changeset)
    end
  end

  defp user_videos(user) do
    assoc(user, :videos)
  end

  def delete(conn, %{"id" => params_id}) do
    video_id = VideoHashId.decode!(params_id)
    user = Guardian.Plug.current_resource(conn)
    video = Repo.get!(user_videos(user), video_id)
    Repo.delete!(video)
    send_resp(conn, :ok, "")
  end

  def update(conn, params = %{"id" => params_id}) do
    # TODO UPDATE without get (from... where... update: ... |> Repo.update(_all))
    # TODO REDUCE THE NUMBER OF QUERIES !
    video_id = VideoHashId.decode!(params_id)
    user = Guardian.Plug.current_resource(conn)
    Video
    |> where([v], v.owner_id == ^user.id)
    |> Video.with_admins()
    |> Repo.get!(video_id)
    |> Video.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, video} ->
        video = video
        |> Map.put(:speakers, video_speakers(video))
        |> update_admins(params)
        render(conn, :show, video: video)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, :error, changeset: changeset)
    end
  end

  def youtube_title(conn, %{"video_uri" => video_uri}) do
    if Regex.match?(~r/(?:youtube\.com\/\S*(?:(?:\/e(?:mbed))?\/|watch\/?\?(?:\S*?&?v\=))|youtu\.be\/)([a-zA-Z0-9_-]{6,11})/, video_uri) do
      case OpenGraph.fetch(video_uri) do
        {:ok, %OpenGraph{title: title}} ->
          json(conn, %{title: HtmlEntities.decode(title)})
        {_, _} ->
          conn
          |> put_status(404)
          |> json(%{errors: ["Cannot fetch video's title"]})
      end
    else
      conn
      |> put_status(404)
      |> json(%{errors: ["Invalid url"]})
    end
  end

  defp video_speakers(video) do
    Repo.all(
      from s in Speaker,
      join: vs in VideoSpeaker, on: vs.speaker_id == s.id,
      where: vs.video_id == ^video.id
    )
  end

  defp update_admins(video, %{"admins" => admins}) do
    # Delete old admins
    admin_ids = Enum.map(admins, &(&1["id"]))
    Repo.delete_all(
      from va in VideoAdmin,
      where: va.video_id == ^video.id,
      where: not (va.user_id in ^admin_ids)
    )

    # Insert new admins
    admin_ids
    |> Enum.map(&VideoAdmin.changeset(%VideoAdmin{}, %{video_id: video.id, user_id: &1}))
    |> Enum.each(fn(admin) -> Repo.insert(admin) end)

    # Fetch & put them in video
    update_admins(video, nil)
  end

  defp update_admins(video, _) do
    new_admins = Repo.all(
      from u in User,
      join: a in VideoAdmin, on: a.user_id == u.id,
      where: a.video_id == ^video.id
    )
    Map.put(video, :admins, new_admins)
  end
end
