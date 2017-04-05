defmodule CaptainFact.VideoController do
  use CaptainFact.Web, :controller
  alias CaptainFact.{Video, VideoAdmin, User, Speaker, VideoSpeaker}

  plug Guardian.Plug.EnsureAuthenticated, [handler: CaptainFact.AuthController]
  when action in [:create, :update, :delete]

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
    render(conn, "index.json", videos: Repo.all(query))
  end

  def index(conn, _params) do
    # TODO Pagination
    videos = Video
    |> Video.with_speakers
    |> Video.with_admins
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
        # TODO : User Ecto.Multi to make all this in one transaction
        video = Map.put(video, :speakers, [])
        video = update_admins(video, video_params)
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
    video = Video
      |> where([v], v.owner_id == ^user.id)
      |> Video.with_admins()
      |> Repo.get!(id)

    #TODO UPDATE without get (from... where... update: ... |> Repo.update(_all))
    #TODO Check ueberauth features for access right

    changeset = Video.changeset(video, params)
    case Repo.update(changeset) do
      {:ok, video} ->
        # TODO REDUCE THE NUMBER OF QUERIES !
        video = Map.put(video, :speakers, Repo.all(
          from s in Speaker,
          join: vs in VideoSpeaker, on: vs.speaker_id == s.id,
          where: vs.video_id == ^video.id
        ))
        video = update_admins(video, params)
        # video = Map.put(video, :admins, Repo.all(from a in VideoAdmin, where: a.video_id == ^video.id))
        render(conn, "show.json", video: video)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(CaptainFact.ChangesetView, "error.json", changeset: changeset)
    end
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
