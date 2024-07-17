defmodule DB.Schema.Source do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sources" do
    field(:url, :string)
    field(:og_url, :string)
    field(:title, :string)
    field(:language, :string)
    field(:site_name, :string)
    field(:file_mime_type, :string)

    timestamps()
  end

  @url_max_length 2048

  # Allow to add localhost urls as sources during tests
  @url_regex if Application.get_env(:db, :env) == :test,
               do:
                 ~r/(^https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))|localhost/,
               else:
                 ~r/^https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

  @doc """
  Get max URL length.
  See https://boutell.com/newfaq/misc/urllength.html
  """
  def url_max_length, do: @url_max_length

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url])
    |> update_change(:url, &prepare_url/1)
    |> changeset_common_validations()
  end

  def changeset_fetched(struct, params) do
    struct
    |> cast(params, [:og_url, :url, :title, :language, :site_name, :file_mime_type])
    |> update_change(:url, &prepare_url/1)
    |> update_change(:og_url, &prepare_url/1)
    |> update_change(:title, &clean_and_truncate/1)
    |> update_change(:language, &String.trim/1)
    |> update_change(:site_name, &clean_and_truncate/1)
    |> changeset_common_validations()
  end

  @regex_contains_http ~r/^https?:\/\//
  def prepare_url(str) do
    str = String.trim(str)
    if Regex.match?(@regex_contains_http, str), do: str, else: "https://" <> str
  end

  defp changeset_common_validations(changeset) do
    changeset
    |> validate_required([:url])
    |> unique_constraint(:url)
    |> validate_format(:url, @url_regex)
    |> validate_length(:url, min: 10, max: @url_max_length)
    |> validate_change(:file_mime_type, &validate_file_mime_type/2)
  end

  defp validate_file_mime_type(:file_mime_type, mime_type) do
    if MIME.extensions(mime_type) != [] do
      []
    else
      [file_mime_type: "Invalid MIME type"]
    end
  end

  defp clean_and_truncate(str) do
    if String.valid?(str) do
      str = DB.Utils.String.trim_all_whitespaces(str)

      if String.length(str) > 250,
        do: String.slice(str, 0, 250) <> "...",
        else: str
    else
      nil
    end
  end
end
