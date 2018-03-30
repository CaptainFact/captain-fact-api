defmodule CaptainFact.Sources do
  alias DB.Repo
  alias DB.Schema.Source

  alias CaptainFact.Sources.Fetcher


  def update_source_metadata(base_source = %Source{}, callback \\ nil) do
    Fetcher.fetch_source_metadata(base_source.url, fn
      metadata when metadata == %{} ->
        nil
      metadata ->
        updated_source = Repo.update!(Source.changeset_fetched(base_source, metadata))
        if !is_nil(callback), do: callback.(updated_source)
    end)
  end
end