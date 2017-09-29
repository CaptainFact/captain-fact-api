Code.require_file("seed_with_csv.exs", __DIR__)
require Logger
require Arc.Ecto.Schema

alias CaptainFact.Repo
alias CaptainFactWeb.Speaker
alias CaptainFactWeb.SpeakerPicture


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

  defp get_wikidata_item_id("http://www.wikidata.org/entity/Q" <> id), do: id

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
      if !changeset.valid? do
        Logger.error(:stderr, "Cannot add speaker #{changes.full_name}: #{inspect(changeset.errors)}")
        nil
      else
        case Repo.get_by(Speaker, wikidata_item_id: changeset.changes.wikidata_item_id) do
          nil ->
            Logger.info("Insert speaker #{changeset.changes.full_name}")
            Repo.insert!(changeset)
          speaker -> speaker
        end
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
  defp fetch_picture(speaker, _), do: Logger.info("Speaker #{speaker.full_name} already have a picture")
end

# Allow usage from shell on dev / test environments - when Mix is installed
if Kernel.function_exported?(Mix, :env, 0) && Application.get_env(:captain_fact, :manual_seed) != true do
  {keywords, args, invalids} = OptionParser.parse(System.argv, strict: [fetch_pictures: :boolean]) |> IO.inspect()

  if Enum.count(invalids) == 0 && Enum.count(args) >= 1,
    do: SeedPoliticians.seed(List.first(args), Keyword.get(keywords, :fetch_pictures), Enum.drop(args, 1)),
    else: Logger.error "Usage: mix run seed_politicians.exs file.csv [--fetch-pictures] [name_filter] [name_filter2]..."
end