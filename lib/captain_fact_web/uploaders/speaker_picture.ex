defmodule CaptainFactWeb.SpeakerPicture do
  use Arc.Definition
  use Arc.Ecto.Definition
  def __storage, do: Arc.Storage.Local

  @versions [:thumb]
  @extension_whitelist ~w(.jpg .jpeg .png)

  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname |> String.downcase
    Enum.member?(@extension_whitelist, file_extension)
  end

  # Define a thumbnail transformation:
  def transform(:thumb, _) do
    {:convert, "-thumbnail 50x50^ -gravity center -extent 50x50 -format png", :png}
  end

  # Override the persisted filenames:
  def filename(version, {_, speaker}) do
    "#{speaker.id}_#{speaker.wikidata_item_id || "no-wiki"}_#{version}"
  end

  # Override the storage directory:
  def storage_dir(_, {_, _}) do
    "resources/speakers"
  end
end
