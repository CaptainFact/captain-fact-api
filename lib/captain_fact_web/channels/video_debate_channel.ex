defmodule CaptainFactWeb.VideoDebateChannel do
  use CaptainFactWeb, :channel

  import CaptainFact.VideoDebateActionCreator, only: [
    action_add: 3, action_create: 3, action_update: 3, action_delete: 3,
    action_remove: 3
  ]
  import CaptainFactWeb.UserSocket, only: [handle_in_authenticated: 4]

  alias Phoenix.View
  alias Ecto.Multi
  alias CaptainFact.Videos.VideoHashId
  alias CaptainFact.Accounts.UserPermissions
  alias CaptainFactWeb.{ Video, VideoView, Speaker, SpeakerView, VideoSpeaker, ChangesetView}


  def join("video_debate:" <> video_id_hash, _payload, socket) do
    with {:ok, video_id} <- VideoHashId.decode(video_id_hash),
         video when not is_nil(video) <- Repo.get(Video.with_speakers(Video), video_id)
    do
      {:ok, View.render_one(video, VideoView, "video.json"), assign(socket, :video_id, video_id)}
    else
      _ -> {:error, "not_found"}
    end
  end

  def handle_in(command, params, socket) do
    handle_in_authenticated(command, params, socket, &handle_in_authenticated!/3)
  end

  @doc """
  Add an existing speaker to the video
  """
  def handle_in_authenticated!("new_speaker", %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :add, :speaker)
    speaker = Repo.get!(Speaker, id)
    changeset = VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video_id})
    Multi.new
    |> Multi.insert(:video_speaker, changeset)
    |> Multi.insert(:action_add, action_add(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, %{}} ->
        rendered_speaker = SpeakerView.render("show.json", speaker: speaker)
        broadcast!(socket, "speaker_added", rendered_speaker)
        {:reply, :ok, socket}
      {:error, _, _reason, _} -> {:reply, :error, socket}
    end
  end

  @doc """
  Create a new speaker for this video
  """
  def handle_in_authenticated!("new_speaker", params, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :create, :speaker)
    speaker_changeset = Speaker.changeset(%Speaker{is_user_defined: true}, params)

    Multi.new
    |> Multi.insert(:speaker, speaker_changeset)
    |> Multi.run(:video_speaker, fn %{speaker: speaker} ->
         # Insert association between video and speaker
         %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}
         |> VideoSpeaker.changeset()
         |> Repo.insert()
       end)
    |> Multi.run(:action_create, fn %{speaker: speaker} ->
         Repo.insert(action_create(user_id, video_id, speaker))
       end)
    |> Repo.transaction()
    |> case do
      {:ok, %{speaker: speaker}} ->
        # Broadcast the speaker
        rendered_speaker = SpeakerView.render("show.json", speaker: speaker)
        broadcast!(socket, "speaker_added", rendered_speaker)
        {:reply, :ok, socket}
      {:error, :speaker, changeset, %{}} ->
        {:reply, {:error, ChangesetView.render("error.json", %{changeset: changeset})}, socket}
    end
  end

  def handle_in_authenticated!("update_speaker", params, socket) do
    UserPermissions.check!(socket.assigns.user_id, :update, :speaker)
    speaker = Repo.get_by!(Speaker, id: params["id"], is_removed: false)
    if !speaker.is_user_defined do
      {:reply, {:error, %{speaker: "forbidden"}}, socket}
    else
      %{user_id: user_id, video_id: video_id} = socket.assigns
      changeset = Speaker.changeset(speaker, params)
      case changeset.changes do
        changes when changes === %{} -> {:reply, :ok, socket}
        _ ->
          Multi.new
          |> Multi.update(:speaker, changeset)
          |> Multi.insert(:action_update, action_update(user_id, video_id, changeset))
          |> Repo.transaction()
          |> case do
            {:ok, %{speaker: speaker}} ->
              rendered_speaker = View.render_one(speaker, SpeakerView, "speaker.json")
              broadcast!(socket, "speaker_updated", rendered_speaker)
              {:reply, :ok, socket}
            {:error, :speaker, changeset = %Ecto.Changeset{}, _} ->
              {:reply, {:error, ChangesetView.render("error.json", %{changeset: changeset})}, socket}
            _ ->
              {:reply, :error, socket}
          end
      end
    end
  end

  def handle_in_authenticated!("remove_speaker", %{"id" => id}, socket) do
    speaker = Repo.get_by!(Speaker, id: id, is_removed: false)
    do_remove_speaker(socket, speaker)
    broadcast!(socket, "speaker_removed", %{id: id})
    {:reply, :ok, socket}
  end

  @max_speakers_search_results 5
  def handle_in_authenticated!("search_speaker", params, socket) do
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

  defp do_remove_speaker(socket, speaker = %{is_user_defined: true}) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :remove, :speaker)
    video_speaker = %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}
    Multi.new
    |> Multi.update(:speaker, Speaker.changeset_remove(speaker))
    |> Multi.delete(:video_speaker, VideoSpeaker.changeset(video_speaker))
    |> Multi.insert(:action_delete, action_delete(user_id, video_id, speaker))
    |> Repo.transaction()
  end

  defp do_remove_speaker(socket, speaker = %{is_user_defined: false}) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :remove, :speaker)
    video_speaker = %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}

    Multi.new
    |> Multi.delete(:video_speaker, VideoSpeaker.changeset(video_speaker))
    |> Multi.insert(:action_remove, action_remove(user_id, video_id, speaker))
    |> Repo.transaction()
  end
end
