defmodule CF.Sources do
  @moduledoc """
  Functions to manage sources and their metadata.
  """

  alias DB.Repo
  alias DB.Schema.Source

  alias CF.Sources.Fetcher

  @doc """
  Get a source from `DB` from its URL. Returns nil if no source exist for
  this URL.
  """
  @spec get_by_url(binary()) :: Source.t() | nil
  def get_by_url(url) do
    Repo.get_by(Source, url: url)
  end

  @doc """
  Fetch a source metadata using `CF.Sources.Fetcher`, update source with it then
  call `callback` (if any) with the update source.
  """
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
