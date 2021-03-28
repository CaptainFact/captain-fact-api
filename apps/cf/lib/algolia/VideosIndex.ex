defmodule CF.Algolia.VideosIndex do
  import Ecto.Query

  use Algoliax.Indexer,
    index_name: :get_index_name,
    repo: DB.Repo,
    schemas: [
      {DB.Schema.Video, [:speakers]}
    ]

  @doc """
  ## Examples

    iex> CF.Algolia.VideosIndex.get_index_name()
    :test_videos
  """
  def get_index_name do
    String.to_atom("#{Application.get_env(:cf, :deploy_env)}_videos")
  end

  @doc """
  ## Examples

    iex> CF.Algolia.VideosIndex.to_be_indexed?(%DB.Schema.Video{unlisted: true})
    false
    iex> CF.Algolia.VideosIndex.to_be_indexed?(%DB.Schema.Video{unlisted: false})
    true
  """
  @impl Algoliax.Indexer
  def to_be_indexed?(video) do
    not video.unlisted
  end

  @impl Algoliax.Indexer
  def build_object(video) do
    video
    |> DB.Repo.preload(:speakers)
    |> Map.update!(:speakers, &update_all_speakers/1)
    |> Map.take(
      ~w(id title hash_id url language is_partner thumbnail youtube_id facebook_id youtube_offset speakers)a
    )
  end

  def reindex_by_id(video_id) do
    DB.Schema.Video
    |> preload(:speakers)
    |> DB.Repo.get(video_id)
    |> save_object()
  end

  def reindex_all_speaker_videos(speaker_id) do
    DB.Schema.Video
    |> join(:inner, [v], s in assoc(v, :speakers))
    |> where([v, s], s.id == ^speaker_id)
    |> preload([v, s], speakers: s)
    |> DB.Repo.all()
    |> save_objects()
  end

  defp update_all_speakers(speakers) do
    Enum.map(speakers, &CF.Algolia.SpeakersIndex.build_object/1)
  end
end
