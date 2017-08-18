Code.require_file("seed_with_csv.exs", __DIR__)
require Logger
require Arc.Ecto.Schema

alias CaptainFact.Repo
alias CaptainFactWeb.Speaker
alias CaptainFactWeb.SpeakerPicture


defmodule SeedPoliticians do
  @activate_filter true
  @filter [
    "sarkozy", "le pen", "hamon", "mélenchon", "fillon", "poutou", "arthaud", "macron", "cheminade",
    "aignan", "lassalle", "asselineau", "trump", "obama"
  ]

  def seed(csv_path, fetch_pictures?) do
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
    case SpeakerPicture.store({picture_url, speaker}) do
      {:ok, picture} ->
        Logger.debug("Fetching picture for #{speaker.full_name} at #{picture_url}")
        speaker
        |> Ecto.Changeset.change(picture: %{file_name: picture, updated_at: Ecto.DateTime.utc})
        |> Repo.update!()
      {:error, :invalid_file_path} ->
        Logger.error("Given image path is invalid : #{picture_url}")
    end
  end
end

{keywords, args, invalids} = OptionParser.parse(System.argv, switches: [fetch_pictures: :boolean])

if Enum.count(invalids) == 0,
  do: SeedPoliticians.seed(List.first(args), Keyword.get(keywords, :fetch_pictures)),
  else: IO.puts "Usage: mix run seed_politicians.exs file.csv --fetch-pictures"
