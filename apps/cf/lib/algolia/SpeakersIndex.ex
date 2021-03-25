defmodule CF.Algolia.SpeakersIndex do
  use Algoliax.Indexer,
    index_name: :get_index_name,
    repo: DB.Repo,
    schemas: [DB.Schema.Speaker]

  @doc """
  ## Examples

    iex> CF.Algolia.SpeakersIndex.get_index_name()
    :test_speakers
  """
  def get_index_name do
    String.to_atom("#{Application.get_env(:cf, :deploy_env)}_speakers")
  end

  @impl Algoliax.Indexer
  def build_object(speaker) do
    Map.take(speaker, ~w(id full_name title slug country wikidata_item_id)a)
  end
end
