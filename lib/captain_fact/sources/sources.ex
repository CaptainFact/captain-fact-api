defmodule CaptainFact.Sources do
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Comments.Comment
  alias CaptainFact.Sources.{Source, Fetcher}


  def update_source_metadata(base_source = %Source{}, callback \\ nil) do
    Fetcher.fetch_source_metadata(base_source.url, fn
      metadata when metadata == %{} -> nil
      metadata ->
        og_url = Map.get(metadata, :url)

        {:ok, source} = Repo.transaction(fn ->
          # Check if we got a new url from metadata
          source = if og_url && og_url != base_source.url,
            do: redirect_source(base_source, og_url),
            else: base_source

          # Update source metadata
          Repo.update!(Source.changeset(source, metadata))
        end)

        if !is_nil(callback), do: callback.(source)
    end)
  end

  defp redirect_source(old_source, new_url) do
    # Get real source or create change existing url
    case Repo.get_by(Source, url: new_url) do
      nil ->
        Source.changeset(old_source, %{url: new_url})
      new_source ->
        # Update all references to prev source
        Comment
        |> where([c], c.source_id == ^old_source.id)
        |> Repo.update_all(set: [source_id: new_source.id])

        # Delete original source
        Repo.delete!(old_source)
        new_source
    end
  end
end