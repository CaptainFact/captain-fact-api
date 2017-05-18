Code.require_file("seed_with_csv.exs", __DIR__)
require Arc.Ecto.Schema

alias CaptainFact.Repo
alias CaptainFact.Speaker
alias CaptainFact.SpeakerPicture

columns_mapping = %{
  "politicianDescription" => :title,
  "image" => :picture,
  "politicianLabel" => :full_name,
  "politician" => :wiki_url
}

SeedWithCSV.seed(__DIR__ <> "/data/french_politicians.csv", columns_mapping, fn changes ->
  # Insert speaker
  {picture_url, changes} = Map.pop(changes, :picture)
  changeset = Speaker.changeset(%Speaker{is_user_defined: false, country: "FR"}, changes)
  if !changeset.valid? do
    IO.puts(:stderr, "Cannot add speaker #{changes.full_name}: #{inspect(changeset.errors)}")
  else
    speaker = Repo.insert!(changeset)

    # Fetch picture and save speaker with it
    {:ok, picture} = SpeakerPicture.store({picture_url, speaker})
    speaker
    |> Ecto.Changeset.change(picture: %{file_name: picture, updated_at: Ecto.DateTime.utc})
    |> Repo.update!()
  end
end)