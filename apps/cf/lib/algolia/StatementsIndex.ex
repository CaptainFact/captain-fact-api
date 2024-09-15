defmodule CF.Algolia.StatementsIndex do
  import Ecto.Query

  use Algoliax.Indexer,
    index_name: :get_index_name,
    repo: DB.Repo,
    schemas: [DB.Schema.Statement]

  @doc """
  ## Examples

    iex> CF.Algolia.StatementsIndex.get_index_name()
    :test_statements
  """
  def get_index_name do
    String.to_atom("#{Application.get_env(:cf, :deploy_env)}_statements")
  end

  @doc """
  ## Examples

    iex> CF.Algolia.StatementsIndex.to_be_indexed?(%DB.Schema.Statement{is_removed: true})
    false
    iex> CF.Algolia.StatementsIndex.to_be_indexed?(%DB.Schema.Statement{is_removed: false})
    true
  """
  @impl Algoliax.Indexer
  def to_be_indexed?(statement) do
    not (statement.is_removed or statement.is_draft)
  end

  @impl Algoliax.Indexer
  def build_object(statement) do
    statement
    |> DB.Repo.preload([:video, :speaker])
    |> Map.update!(:video, &build_video(&1))
    |> Map.update!(:speaker, &build_speaker(&1))
    |> Map.take(~w(id text time video speaker)a)
  end

  def reindex_all_speaker_statements(speaker_id) do
    DB.Schema.Statement
    |> where([s], s.speaker_id == ^speaker_id)
    |> DB.Repo.all()
    |> save_objects()
  end

  defp build_video(video) do
    Map.take(video, ~w(id title hash_id youtube_id facebook_id url)a)
  end

  defp build_speaker(nil), do: nil
  defp build_speaker(speaker), do: CF.Algolia.SpeakersIndex.build_object(speaker)
end
