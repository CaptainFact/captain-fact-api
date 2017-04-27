defmodule CaptainFact.VideoDebateChannel do
  use CaptainFact.Web, :channel

  alias CaptainFact.{ Statement, Video, VideoView, Speaker, SpeakerView}
  alias CaptainFact.{ VideoSpeaker, VideoHashId }
  alias Phoenix.View


  def join("video_debate:" <> video_id_hash, _payload, socket) do
    video_id = VideoHashId.decode!(video_id_hash)
    is_authentified = if Guardian.Phoenix.Socket.current_resource(socket),
      do: true, else: false
    video = Video
      |> Video.with_speakers
      |> Repo.get!(video_id)
    socket = socket
      |> assign(:video_id, video_id)
      |> assign(:is_authentified, is_authentified)
    rendered_video = View.render_one(video, VideoView, "video.json")
    {:ok, rendered_video, assign(socket, :video_id, video_id)}
  end

  def handle_in(command, params, socket) do
    case socket.assigns.is_authentified do
      false -> {:reply, :error, socket}
      true -> handle_in_authentified(command, params, socket)
    end
  end

  @doc """
  Add an existing speaker to the video
  """
  def handle_in_authentified("new_speaker", %{"id" => id}, socket) do
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
  def handle_in_authentified("new_speaker", options, socket) do
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

  def handle_in_authentified("update_speaker", params, socket) do
    speaker = Repo.get!(Speaker, params["id"])
    if speaker.is_user_defined do
      changeset = Speaker.changeset(speaker, params)
      case Repo.update(changeset) do
        {:ok, speaker} ->
          rendered_speaker = Phoenix.View.render_one(speaker, CaptainFact.SpeakerView, "speaker.json")
          broadcast!(socket, "speaker_updated", rendered_speaker)
          {:reply, :ok, socket}
        {:error, _error} ->
          {:reply, :error, socket}
      end
    else
      {:reply, {:error, %{speaker: "Forbidden"}}, socket}
    end
  end

  def handle_in_authentified("remove_speaker", %{"id" => id}, socket) do
    do_remove_speaker(Repo.get(Speaker, id), socket.assigns.video_id)
    broadcast!(socket, "speaker_removed", %{id: id})
    {:reply, :ok, socket}
  end

  @max_speakers_search_results 5
  def handle_in_authentified("search_speaker", params, socket) do
    query = "%#{params["query"]}%"
    speakers_query =
      from s in Speaker,
      left_join: vs in VideoSpeaker, on: vs.speaker_id == s.id,
      where: is_nil(vs.video_id) or vs.video_id != ^socket.assigns.video_id,
      where: s.is_user_defined == false,
      where: fragment("unaccent(?) ILIKE unaccent(?)", s.full_name, ^query),
      select: %{id: s.id, full_name: s.full_name},
      limit: @max_speakers_search_results
    {:reply, {:ok, %{speakers: Repo.all(speakers_query)}}, socket}
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
end
