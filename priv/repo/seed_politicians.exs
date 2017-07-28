Code.require_file("seed_with_csv.exs", __DIR__)
require Logger
require Arc.Ecto.Schema

alias CaptainFact.Repo
alias CaptainFactWeb.Speaker
alias CaptainFactWeb.SpeakerPicture


defmodule SeedPoliticians do
  @filename "/data/french_politicians.csv"
  @activate_filter true
  @filter ["sarkozy", "pen", "hamon", "mélenchon", "fillon", "poutou", "arthaud", "macron", "cheminade", "aignan", "lassalle", "asselineau"]

  def seed(fetch_pictures?) do
    csv_path = __DIR__ <> @filename
    seed_func = if fetch_pictures?, do: &seed_politician_with_picture/1, else: &seed_politician/1
    SeedWithCSV.seed(csv_path, seed_func, %{
      "image" => :picture,
      "politicianLabel" => :full_name,
      "politician" => {:wikidata_item_id, &get_wikidata_item_id/1}
    })
  end

  defp get_wikidata_item_id("http://www.wikidata.org/entity/Q" <> id), do: id

  defp seed_politician_with_picture(changes) do
    {picture_url, changes} = Map.pop(changes, :picture)
    with speaker when not is_nil(speaker) <- seed_politician(changes),
      do: fetch_picture(speaker, picture_url)
  end

  defp seed_politician(changes) do
    if filter(changes) do
      changes =
        changes
        |> Map.delete(:picture)
        |> Map.put(:title, "Politician")

      changeset = Speaker.changeset(%Speaker{is_user_defined: false, country: "FR"}, changes)
      if !changeset.valid? do
        IO.puts(:stderr, "Cannot add speaker #{changes.full_name}: #{inspect(changeset.errors)}")
        nil
      else
        case Repo.get_by(Speaker, wikidata_item_id: changeset.changes.wikidata_item_id) do
          nil ->
            Logger.info("Insert speaker #{changeset.changes.full_name}")
            Repo.insert!(changeset)
          _ -> nil # If speaker already exists, skip it
        end
      end
    end
  end

  defp filter(changes) do
    if !@activate_filter do
      true
    else
      lower_name = String.downcase(changes.full_name)
      Enum.any?(@filter, &String.contains?(lower_name, &1))
    end
  end

  defp fetch_picture(speaker, picture_url) do
    {:ok, picture} = SpeakerPicture.store({picture_url, speaker})
    Logger.debug("Fetching picture for #{speaker.full_name} at #{picture_url}")
    speaker
    |> Ecto.Changeset.change(picture: %{file_name: picture, updated_at: Ecto.DateTime.utc})
    |> Repo.update!()
  end
end

SeedPoliticians.seed(true)