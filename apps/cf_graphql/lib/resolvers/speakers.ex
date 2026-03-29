defmodule CF.Graphql.Resolvers.Speakers do
  @moduledoc """
  Resolver for speaker-related GraphQL operations
  """

  alias DB.Repo
  alias DB.Schema.Speaker
  alias CF.Algolia.SpeakersIndex
  alias CF.Graphql.Subscriptions
  alias CF.Speakers

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
    Speakers.search_by_name(query, limit)
  end

  def search_speakers(root, %{query: query}, info) do
    search_speakers(root, %{query: query, limit: 5}, info)
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

    speaker = Repo.get!(Speaker, speaker_id)

    case Speakers.add_speaker_to_video(user_id, video_id, speaker) do
      {:ok, speaker} ->
        Subscriptions.publish_speaker_added(speaker, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        {:ok, speaker}

      {:error, :speaker_already_on_video} ->
        {:error, "Speaker already added to this video"}

      {:error, _} ->
        {:error, "Failed to add speaker"}
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

    case Speakers.create_speaker_and_add_to_video(user_id, video_id, full_name) do
      {:ok, speaker} ->
        Subscriptions.publish_speaker_added(speaker, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        SpeakersIndex.save_object(speaker)
        {:ok, speaker}

      {:error, :invalid_speaker} ->
        {:error, "Invalid speaker data"}

      {:error, _} ->
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

    case Speakers.remove_speaker_from_video(user_id, video_id, speaker) do
      {:ok, speaker_id} ->
        Subscriptions.publish_speaker_removed(speaker_id, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        {:ok, %{id: speaker_id}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Update an existing speaker
  """
  def update_speaker(_root, %{id: id} = args, %{context: %{user: user}}) do
    user_id = user.id
    speaker = Repo.get!(Speaker, id)
    update_args = Map.delete(args, :id)

    case Speakers.update_speaker(user_id, speaker, update_args) do
      {:ok, updated_speaker} ->
        Task.start(fn ->
          Enum.each(Speakers.video_ids_for_speaker(speaker.id), fn video_id ->
            Subscriptions.publish_speaker_updated(updated_speaker, video_id)
          end)
        end)

        Task.start(fn ->
          CF.Algolia.SpeakersIndex.save_object(updated_speaker)
        end)

        {:ok, updated_speaker}

      {:error, _changeset} ->
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

    case Speakers.restore_speaker_to_video(user_id, video_id, speaker) do
      {:ok, %{speaker: speaker, action: action}} ->
        Subscriptions.publish_video_history_action(action, video_id)
        Subscriptions.publish_speaker_added(speaker, video_id)
        CF.Algolia.VideosIndex.reindex_by_id(video_id)
        {:ok, speaker}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
