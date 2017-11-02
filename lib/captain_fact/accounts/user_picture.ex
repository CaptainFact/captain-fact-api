defmodule CaptainFact.Accounts.UserPicture do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:thumb, :mini_thumb]
  @extension_whitelist ~w(.jpg .jpeg .png)

  # Whitelist file extensions:
  def validate({file, _}) do
    true # TODO - Just checking with @extension_whitelist causes problems when fetching from Facebook
  end

  # Versions
  def transform(:thumb, _) do
    {:convert, "-thumbnail 96x96^ -gravity center -extent 96x96 -format jpg", :jpg}
  end

  def transform(:mini_thumb, _) do
    {:convert, "-thumbnail 48x48^ -gravity center -extent 48x48 -format jpg", :jpg}
  end

  # Override the persisted filenames:
  def filename(version, {_, %{id: user_id}}) when version == :thumb or version == :mini_thumb do
    "#{user_id}_#{Atom.to_string(version)}"
  end

  # Override the storage directory:
  def storage_dir(_, {_, _}) do
    "resources/users"
  end
end
