defmodule CaptainFact.VideoDebateChannel do
  use CaptainFact.Web, :channel

  alias CaptainFact.Statement
  alias CaptainFact.Video
  alias CaptainFact.VideoView
  alias CaptainFact.Speaker
  alias CaptainFact.SpeakerView
  alias CaptainFact.VideoSpeaker
  alias Phoenix.View


  def join("video_debate:" <> video_id_str, _payload, socket) do
    video_id = String.to_integer(video_id_str)
    video = Video
    |> Video.with_speakers
    |> Video.with_admins
    |> Repo.get!(video_id)
    user = Guardian.Phoenix.Socket.current_resource(socket)
    if Video.has_access(video, user) do
      rendered_video = View.render_one(video, VideoView, "video.json")
      socket = socket
      |> assign(:video_id, video_id)
      |> assign(:is_admin, Video.is_admin(video, user))
      {:ok, rendered_video, socket}
    else
      {:error, %{reason: "You're not authorized to see this video"}}
    end
  end

  def handle_in(command, params, socket) do
    case socket.assigns.is_admin do
      true -> admin_handle_in(command, params, socket)
      false -> {:reply, :error, socket}
    end
  end

  @doc """
  Add an existing speaker to the video
  """
  def admin_handle_in("new_speaker", %{"id" => id}, socket) do
    speaker = Repo.get!(Speaker, id)
    %VideoSpeaker{speaker_id: speaker.id, video_id: socket.assigns.video_id}
      |> VideoSpeaker.changeset()
      |> Repo.insert!()
    rendered_speaker = SpeakerView.render("show.json", speaker: speaker)
    broadcast!(socket, "new_speaker", rendered_speaker)
    {:reply, :ok, socket}
  end

  @doc """
  Add a new speaker to the video
  """
  def admin_handle_in("new_speaker", options, socket) do
    speaker_changeset = Speaker.changeset(%Speaker{is_user_defined: true}, options)
    case Repo.insert(speaker_changeset) do
      {:ok, speaker} ->
        # Insert association between video and speaker
        %VideoSpeaker{speaker_id: speaker.id, video_id: socket.assigns.video_id}
        |> VideoSpeaker.changeset()
        |> Repo.insert!()

        # Broadcast the speaker
        rendered_speaker = SpeakerView.render("show.json", speaker: speaker)
        broadcast!(socket, "new_speaker", rendered_speaker)
        {:reply, :ok, socket}
      {:error, _reason} ->
        {:reply, :error, socket}
    end
  end

  def admin_handle_in("update_speaker", params, socket) do
    speaker = Repo.get!(Speaker, params["id"])
    changeset = Speaker.changeset(speaker, params)
    case Repo.update(changeset) do
      {:ok, speaker} ->
        rendered_speaker = Phoenix.View.render_one(speaker, CaptainFact.SpeakerView, "speaker.json")
        broadcast!(socket, "speaker_updated", rendered_speaker)
        {:reply, :ok, socket}
      {:error, _error} ->
        {:reply, :error, socket}
    end
  end

  def admin_handle_in("remove_speaker", %{"id" => id}, socket) do
    # Delete association
    # VideoSpeaker
    # |> where(speaker_id: ^id, video_id: ^socket.assigns.video_id)
    # |> Repo.delete_all()
    # Delete all statements made by the speaker on this video
    # Statement
    # |> where(speaker_id: ^id, video_id: ^socket.assigns.video_id)
    # |> Repo.delete_all()
    do_remove_speaker(Repo.get(Speaker, id), socket.assigns.video_id)
    # TODO check is_user_defined
    # TODO + check no other usages
    # TODO finally remove speaker
    broadcast!(socket, "speaker_removed", %{id: id})
    {:reply, :ok, socket}
  end

  defp do_remove_speaker(speaker = %{is_user_defined: true}, _) do
    Repo.delete!(speaker)
  end

  defp do_remove_speaker(speaker = %{is_user_defined: false}, video_id) do
    # Delete all statements made by the speaker on this video
    Statement
    |> where(speaker_id: ^speaker.id, video_id: ^video_id)
    |> Repo.delete_all()
    # Delete link between speaker and video
    Repo.delete!(VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video_id}))
  end

  @max_speakers_search_results 5
  def admin_handle_in("search_speaker", params, socket) do
    query = "%#{params["query"]}%"
    speakers_query =
      from s in Speaker,
      left_join: vs in VideoSpeaker, on: vs.speaker_id == s.id,
      where: is_nil(vs.video_id) or vs.video_id != ^socket.assigns.video_id,
      where: s.is_user_defined == false,
      where: ilike(s.full_name, ^query),
      select: %{id: s.id, full_name: s.full_name},
      limit: @max_speakers_search_results
    {:reply, {:ok, %{speakers: Repo.all(speakers_query)}}, socket}
  end

  # current_user = Guardian.Plug.current_resource(conn)
  # query_string = query_string
  #   |> URI.decode()
  #   |> String.replace(~r/%|\*/, "", global: true)
  # query_string = "%#{query_string}%"
  # users_query =
  #   from u in User,
  #   where: u.id != ^current_user.id,
  #   where: like(u.username, ^query_string) or like(u.name, ^query_string),
  #   select: [:id, :username, :name],
  #   limit: @max_users_search_results
  #
  # render(conn, "index_public.json", users: Repo.all(users_query))
end
