defmodule CF.RestApi.VideoDebateChannel do
  use CF.RestApi, :channel
  alias CF.RestApi.Presence

  import CF.Actions.ActionCreator,
    only: [
      action_add: 3,
      action_create: 2,
      action_update: 2,
      action_remove: 3
    ]

  import CF.RestApi.UserSocket, only: [handle_in_authenticated: 4]

  alias Phoenix.View
  alias Ecto.Multi
  alias DB.Schema.User
  alias DB.Schema.Video
  alias DB.Schema.Speaker
  alias DB.Schema.VideoSpeaker

  alias CF.Videos
  alias CF.Accounts.UserPermissions
  alias CF.Notifications.Subscriptions
  alias CF.RestApi.{VideoView, SpeakerView, ChangesetView}

  def join("video_debate:" <> video_hash_id, _payload, socket) do
    Video
    |> Video.with_speakers()
    |> Repo.get_by(hash_id: video_hash_id)
    |> case do
      nil ->
        {:error, "not_found"}

      video ->
        rendered_video =
          View.render_one(
            video,
            VideoView,
            "video_with_subscription.json",
            is_subscribed: is_subscribed(socket.assigns.user_id, video)
          )

        send(self(), :after_join)
        {:ok, rendered_video, assign(socket, :video_id, video.id)}
    end
  end

  @doc """
  Register a public connection in presence tracker
  """
  def handle_info(:after_join, socket = %{assigns: %{user_id: nil}}) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} = Presence.track(socket, :viewers, %{})
    {:noreply, socket}
  end

  @doc """
  Register a user connection in presence tracker
  """
  def handle_info(:after_join, socket = %{assigns: %{user_id: user_id}}) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} = Presence.track(socket, :users, %{user_id: user_id})
    {:noreply, socket}
  end

  def handle_in(command, params, socket) do
    handle_in_authenticated(command, params, socket, &handle_in_authenticated!/3)
  end

  @doc """
  Shift all video's statements
  """
  def handle_in_authenticated!("shift_statements", offsets, socket) do
    user = Repo.get(DB.Schema.User, socket.assigns.user_id)

    case Videos.shift_statements(user, socket.assigns.video_id, offsets) do
      {:ok, video} ->
        rendered_video =
          video
          |> DB.Repo.preload(:speakers)
          |> View.render_one(VideoView, "video.json")

        broadcast!(socket, "video_updated", %{video: rendered_video})
        {:reply, :ok, socket}

      {:error, _} ->
        {:reply, :error, socket}
    end
  end

  @doc """
  Add an existing speaker to the video
  """
  def handle_in_authenticated!("new_speaker", %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :add, :speaker)
    speaker = Repo.get!(Speaker, id)
    changeset = VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video_id})

    Multi.new()
    |> Multi.insert(:video_speaker, changeset)
    |> Multi.insert(:action_add, action_add(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, %{}} ->
        rendered_speaker = SpeakerView.render("show.json", speaker: speaker)
        broadcast!(socket, "speaker_added", rendered_speaker)
        {:reply, :ok, socket}

      {:error, _, %{errors: errors}, _} ->
        if errors[:video] == {"has already been taken", []},
          do: {:reply, {:error, %{error: "action_already_done"}}, socket},
          else: {:reply, :error, socket}
    end
  end

  @doc """
  Create a new speaker and add it to the video
  """
  def handle_in_authenticated!("new_speaker", params, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :create, :speaker)
    speaker_changeset = Speaker.changeset(%Speaker{}, params)

    Multi.new()
    |> Multi.insert(:speaker, speaker_changeset)
    |> Multi.run(:video_speaker, fn %{speaker: speaker} ->
      # Insert association between video and speaker
      %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}
      |> VideoSpeaker.changeset()
      |> Repo.insert()
    end)
    |> Multi.run(:action_create, fn %{speaker: speaker} ->
      Repo.insert(action_create(user_id, speaker))
    end)
    |> Multi.run(:action_add, fn %{speaker: speaker} ->
      Repo.insert(action_add(user_id, video_id, speaker))
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

      _ ->
        {:reply, {:error, "Unknown error", socket}}
    end
  end

  def handle_in_authenticated!("update_speaker", params, socket) do
    user_id = socket.assigns.user_id
    UserPermissions.check!(user_id, :update, :speaker)
    speaker = Repo.get!(Speaker, params["id"])
    changeset = Speaker.changeset(speaker, params)

    case changeset.changes do
      changes when changes === %{} ->
        {:reply, :ok, socket}

      _ ->
        Multi.new()
        |> Multi.update(:speaker, changeset)
        |> Multi.insert(:action_update, action_update(user_id, changeset))
        |> Repo.transaction()
        |> case do
          {:ok, %{speaker: speaker}} ->
            rendered_speaker = View.render_one(speaker, SpeakerView, "speaker.json")
            broadcast!(socket, "speaker_updated", rendered_speaker)
            {:reply, :ok, socket}

          {:error, :speaker, changeset = %Ecto.Changeset{}, _} ->
            {:reply, {:error, ChangesetView.render("error.json", %{changeset: changeset})},
             socket}

          _ ->
            {:reply, :error, socket}
        end
    end
  end

  def handle_in_authenticated!("remove_speaker", %{"id" => id}, socket) do
    speaker = Repo.get!(Speaker, id)
    do_remove_speaker(socket, speaker)
    broadcast!(socket, "speaker_removed", %{id: id})
    {:reply, :ok, socket}
  end

  @max_speakers_search_results 5
  def handle_in_authenticated!("search_speaker", params, socket) do
    query = "%#{params["query"]}%"

    speakers_query =
      from(
        s in Speaker,
        where: fragment("unaccent(?) ILIKE unaccent(?)", s.full_name, ^query),
        group_by: s.id,
        select: %{id: s.id, full_name: s.full_name},
        limit: @max_speakers_search_results
      )

    {:reply, {:ok, %{speakers: Repo.all(speakers_query)}}, socket}
  end

  def handle_in_authenticated!("change_subscription", %{"subscribed" => subscribed}, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    video = %Video{id: socket.assigns.video_id}

    if subscribed do
      Subscriptions.subscribe(user, video)
    else
      Subscriptions.unsubscribe(user, video)
    end

    {:reply, :ok, socket}
  end

  defp do_remove_speaker(socket, speaker) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :remove, :speaker)
    video_speaker = %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}

    Multi.new()
    |> Multi.delete(:video_speaker, VideoSpeaker.changeset(video_speaker))
    |> Multi.insert(:action_remove, action_remove(user_id, video_id, speaker))
    |> Repo.transaction()
  end

  # Check wether current user_id from socket is subscribed to video's notifications
  defp is_subscribed(nil, _) do
    false
  end

  defp is_subscribed(user_id, video) do
    Subscriptions.is_subscribed(%User{id: user_id}, video)
  end
end
