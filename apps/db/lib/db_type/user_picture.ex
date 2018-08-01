defmodule DB.Type.UserPicture do
  @moduledoc """
  User profile picture. Map the Ecto type to an URL using ARC
  """

  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:thumb, :mini_thumb]
  # TODO  @extension_whitelist ~w(.jpg .jpeg .png)

  @doc """
  Validate file extension.
  """
  def validate({_file, _}) do
    # TODO Arc currently return a file without extension when fetching a URL with redirection
    # like `https://graph.facebook.com/xxxxxxxxxxx/picture?type=normal`.
    # See [this issue](https://github.com/stavro/arc/issues/227) for more info.
    #
    # As we only use this upload with Facebook API, we can avoid checking file extension (Facebook already
    # did it for us) but this should be fixed before considering uploading user's pictures
    # --------------------------------------
    true
  end

  # Versions
  def transform(:thumb, _) do
    {:convert, "-thumbnail 96x96^ -gravity center -extent 96x96 -format jpg", :jpg}
  end

  def transform(:mini_thumb, _) do
    {:convert, "-thumbnail 24x24^ -gravity center -extent 24x24 -format jpg", :jpg}
  end

  # Override the persisted filenames:
  def filename(version, {_, %{id: user_id}}) when version in [:thumb, :mini_thumb] do
    "#{user_id}_#{Atom.to_string(version)}"
  end

  # Use adorable.io as default profile picture provider
  def default_url(:thumb, %{id: id}) do
    "https://api.adorable.io/avatars/96/#{id}.png"
  end

  def default_url(:mini_thumb, %{id: id}) do
    "https://api.adorable.io/avatars/24/#{id}.png"
  end

  # Override the storage directory:
  def storage_dir(_, {_, _}) do
    "resources/users"
  end
end
