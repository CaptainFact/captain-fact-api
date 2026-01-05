defmodule CF.Graphql.Resolvers.Speakers do
  @moduledoc """
  Resolver for speaker-related GraphQL operations
  """

  import Ecto.Query
  alias Kaur.Result
  alias Ecto.Multi
  alias DB.Repo
  alias DB.Schema.Speaker
  alias DB.Schema.VideoSpeaker
  alias CF.Accounts.UserPermissions
  alias CF.Actions.ActionCreator
  alias CF.Graphql.Subscriptions
  alias CF.Algolia.SpeakersIndex

  import CF.Actions.ActionCreator,
    only: [action_add: 3, action_create: 2, action_remove: 3, action_restore: 3]

  def picture(speaker, _, _) do
    {:ok, DB.Type.SpeakerPicture.full_url(speaker, :thumb)}
  end

  @doc """
  Get a single speaker by ID or slug
  """
  def get(_root, %{id: id}, _info) do
    case Repo.get(Speaker, id) do
      nil -> {:error, "Speaker #{id} doesn't exist"}
      speaker -> {:ok, speaker}
    end
  end

  def get(_root, %{slug: slug}, _info) do
    slug = Slugger.slugify(slug)

    case Repo.get_by(Speaker, slug: slug) do
      nil -> {:error, "Speaker with slug #{slug} doesn't exist"}
      speaker -> {:ok, speaker}
    end
  end

  @doc """
  Search for speakers by name
  """
  def search_speakers(_root, %{query: query}, _info) when byte_size(query) < 3 do
    {:ok, []}
  end

  def search_speakers(_root, %{query: query, limit: limit}, _info) do
    query_pattern = "%#{query}%"

    speakers_query =
      from(
        s in Speaker,
        where: fragment("unaccent(?) ILIKE unaccent(?)", s.full_name, ^query_pattern),
        group_by: s.id,
        select: %{id: s.id, full_name: s.full_name, slug: s.slug, picture: s.picture},
        limit: ^limit
      )

    {:ok, Repo.all(speakers_query)}
  end

  def search_speakers(_root, %{query: query}, _info) do
    search_speakers(_root, %{query: query, limit: 5}, _info)
  end

  @doc """
  Add an existing speaker to a video
  """
  def add_speaker_to_video(_root, %{video_id: video_id, speaker_id: speaker_id}, %{
        context: %{user: user}
      }) do
    user_id = user.id
    video_id = String.to_integer(video_id)
    speaker_id = String.to_integer(speaker_id)

    UserPermissions.check!(user_id, :add, :speaker)

    speaker = Repo.get!(Speaker, speaker_id)
    changeset = VideoSpeaker.changeset(%VideoSpeaker{speaker_id: speaker.id, video_id: video_id})

    Multi.new()
    |> Multi.insert(:video_speaker, changeset)
    |> Multi.insert(:action_add, action_add(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, %{}} ->
        Subscriptions.publish_speaker_added(speaker, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        {:ok, speaker}

      {:error, _, %{errors: errors}, _} ->
        if errors[:video] == {"has already been taken", []},
          do: {:error, "Speaker already added to this video"},
          else: {:error, "Failed to add speaker"}
    end
  end

  @doc """
  Create a new speaker and add it to a video
  """
  def create_speaker(_root, %{video_id: video_id, full_name: full_name}, %{
        context: %{user: user}
      }) do
    user_id = user.id
    video_id = String.to_integer(video_id)

    UserPermissions.check!(user_id, :create, :speaker)

    speaker_changeset = Speaker.changeset(%Speaker{}, %{full_name: full_name})

    Multi.new()
    |> Multi.insert(:speaker, speaker_changeset)
    |> Multi.run(:video_speaker, fn _repo, %{speaker: speaker} ->
      # Insert association between video and speaker
      %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}
      |> VideoSpeaker.changeset()
      |> Repo.insert()
    end)
    |> Multi.run(:action_create, fn _repo, %{speaker: speaker} ->
      Repo.insert(action_create(user_id, speaker))
    end)
    |> Multi.run(:action_add, fn _repo, %{speaker: speaker} ->
      Repo.insert(action_add(user_id, video_id, speaker))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{speaker: speaker}} ->
        Subscriptions.publish_speaker_added(speaker, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        SpeakersIndex.save_object(speaker)
        {:ok, speaker}

      {:error, :speaker, changeset, %{}} ->
        {:error, "Invalid speaker data"}

      _ ->
        {:error, "Failed to create speaker"}
    end
  end

  @doc """
  Remove a speaker from a video
  """
  def remove_speaker_from_video(_root, %{video_id: video_id, speaker_id: speaker_id}, %{
        context: %{user: user}
      }) do
    user_id = user.id
    video_id = String.to_integer(video_id)
    speaker_id = String.to_integer(speaker_id)

    speaker = Repo.get!(Speaker, speaker_id)
    UserPermissions.check!(user_id, :remove, :speaker)

    video_speaker = %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}

    Multi.new()
    |> Multi.delete(:video_speaker, VideoSpeaker.changeset(video_speaker))
    |> Multi.insert(:action_remove, action_remove(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        Subscriptions.publish_speaker_removed(speaker_id, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        {:ok, %{id: speaker_id}}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Update an existing speaker
  """
  def update_speaker(_root, %{id: id} = args, %{context: %{user: user}}) do
    user_id = user.id
    speaker = Repo.get!(Speaker, id)
    UserPermissions.check!(user_id, :update, :speaker)

    # Remove id from args as it's not part of the changeset
    update_args = Map.delete(args, :id)

    speaker
    |> Speaker.changeset(update_args)
    |> Repo.update()
    |> case do
      {:ok, updated_speaker} ->
        # Publish subscription updates asynchronously
        Task.start(fn ->
          speaker_video_ids =
            Repo.all(
              from(vs in VideoSpeaker, where: vs.speaker_id == ^speaker.id, select: vs.video_id)
            )

          Enum.each(speaker_video_ids, fn video_id ->
            Subscriptions.publish_speaker_updated(updated_speaker, video_id)
          end)
        end)

        # Update search index asynchronously
        Task.start(fn ->
          CF.Algolia.SpeakersIndex.save_object(updated_speaker)
        end)

        {:ok, updated_speaker}

      {:error, changeset} ->
        {:error, "Failed to update speaker"}
    end
  end

  @doc """
  Restore a removed speaker to a video
  """
  def restore_speaker(_root, %{speaker_id: speaker_id, video_id: video_id}, %{
        context: %{user: user}
      }) do
    user_id = user.id
    video_id = String.to_integer(video_id)
    speaker_id = String.to_integer(speaker_id)

    speaker = Repo.get!(Speaker, speaker_id)
    UserPermissions.check!(user_id, :restore, :speaker)

    video_speaker = %VideoSpeaker{speaker_id: speaker.id, video_id: video_id}

    Multi.new()
    |> Multi.insert(:video_speaker, VideoSpeaker.changeset(video_speaker))
    |> Multi.insert(:action_restore, action_restore(user_id, video_id, speaker))
    |> Repo.transaction()
    |> case do
      {:ok, %{action_restore: action}} ->
        Subscriptions.publish_video_history_action(action, video_id)
        Subscriptions.publish_speaker_added(speaker, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        {:ok, speaker}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end
end
