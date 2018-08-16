Code.require_file("seed_with_csv.exs", __DIR__)
require Logger
require Arc.Ecto.Schema

alias DB.Repo
alias DB.Schema.Speaker
alias CaptainFact.Speakers

defmodule SeedPoliticians do
  def seed(csv_path, fetch_pictures? \\ true, names_filter \\ []) do
    seed_func = if fetch_pictures?, do: &seed_politician_with_picture/2, else: &seed_politician/2
    names_filter = Enum.map(names_filter, &String.downcase/1)

    SeedWithCSV.seed(csv_path, seed_func, names_filter, %{
      "image" => :picture,
      "politicianLabel" => :full_name,
      "politician" => {:wikidata_item_id, &get_wikidata_item_id/1},
      "countryCode" => :country
    })
  end

  defp get_wikidata_item_id("http://www.wikidata.org/entity/" <> id), do: id

  defp seed_politician_with_picture(changes, names_filter) do
    {picture_url, changes} = Map.pop(changes, :picture)

    with speaker when not is_nil(speaker) <- seed_politician(changes, names_filter),
         do: fetch_picture(speaker, picture_url)
  end

  defp seed_politician(changes, names_filter) do
    if filter(changes, names_filter) do
      changes =
        changes
        |> Map.delete(:picture)
        |> Map.put(:title, "Politician")

      changeset = Speaker.changeset(%Speaker{is_user_defined: false}, changes)

      if changeset.valid? do
        case Repo.get_by(Speaker, wikidata_item_id: changeset.changes.wikidata_item_id) do
          nil ->
            Logger.info("Insert speaker #{changeset.changes.full_name}")
            Repo.insert!(changeset)

          speaker ->
            speaker
        end
      else
        Logger.error(
          :stderr,
          "Cannot add speaker #{changes.full_name}: #{inspect(changeset.errors)}"
        )

        nil
      end
    end
  end

  defp filter(changes, names_filter) do
    # Politicians for which name failed to resolve to english have a name like QXXXXX with XXXXX being a number
    !Regex.match?(~r/Q\d+/i, changes.full_name) && filter_names(changes, names_filter)
  end

  defp filter_names(_, []), do: true

  defp filter_names(changes, names_filter) do
    lower_name = String.downcase(changes.full_name)
    Enum.any?(names_filter, &String.contains?(lower_name, &1))
  end

  defp fetch_picture(speaker = %{picture: nil}, picture_url) do
    case Speakers.fetch_picture(speaker, picture_url) do
      {:ok, _} ->
        Logger.debug(fn ->
          "Fetched picture for #{speaker.full_name} at #{picture_url}"
        end)

      {:error, reason} ->
        Logger.warn(fn ->
          "Fetch picture #{picture_url} failed for #{speaker.full_name} (#{reason})"
        end)
    end
  end

  defp fetch_picture(speaker, _),
    do: Logger.info("Speaker #{speaker.full_name} already have a picture")
end
