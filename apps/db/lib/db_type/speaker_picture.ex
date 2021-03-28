defmodule DB.Type.SpeakerPicture do
  @moduledoc """
  Speaker picture. Map the Ecto type to an URL using ARC
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:thumb]
  @extension_whitelist ~w(.jpg .jpeg .png)

  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()
    Enum.member?(@extension_whitelist, file_extension)
  end

  # The default `url` function has a bug where it does not include the host
  def full_url(speaker, version) do
    path = url({speaker.picture, speaker}, version)

    cond do
      is_nil(path) -> nil
      String.starts_with?(path, "/") -> "#{Application.get_env(:arc, :asset_host)}/#{path}"
      true -> path
    end
  end

  # Define a thumbnail transformation:
  def transform(:thumb, _) do
    {:convert, "-thumbnail 50x50^ -gravity center -extent 50x50 -format jpg", :jpg}
  end

  # Override the persisted filenames:
  def filename(version, {_, speaker}) do
    "#{speaker.id}_#{version}"
  end

  # Override the storage directory:
  def storage_dir(_, {_, _}) do
    "resources/speakers"
  end
end
