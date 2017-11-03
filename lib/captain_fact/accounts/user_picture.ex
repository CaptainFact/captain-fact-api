defmodule CaptainFact.Accounts.UserPicture do
  use Arc.Definition
  use Arc.Ecto.Definition

  @versions [:thumb, :mini_thumb]
  # TODO  @extension_whitelist ~w(.jpg .jpeg .png)

  @doc"""
  Validate file extension.
  """
  def validate({_file, _}) do
    # TODO Arc currently return a file without extension when fetching a URL with redirection
    # like `https://graph.facebook.com/xxxxxxxxxxx/picture?type=normal`.
    # See [this issue](https://github.com/stavro/arc/issues/227) for more info.
    #
    # As we only use this upload with Facebook API, we can avoid checking file extension (Facebook already
    # did it for us) but this should be fixed before considering uploading user's pictures
    #--------------------------------------
    true
  end

  # Versions
  def transform(:thumb, _) do
    {:convert, "-thumbnail 96x96^ -gravity center -extent 96x96 -format jpg", :jpg}
  end

  def transform(:mini_thumb, _) do
    {:convert, "-thumbnail 48x48^ -gravity center -extent 48x48 -format jpg", :jpg}
  end

  # Override the persisted filenames:
  def filename(version, {_, %{id: user_id}}) when version in [:thumb, :mini_thumb] do
    "#{user_id}_#{Atom.to_string(version)}"
  end

  # Override the storage directory:
  def storage_dir(_, {_, _}) do
    "resources/users"
  end
end
