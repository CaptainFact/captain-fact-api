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
    |> validate_length(:url, min: 10, max: @url_max_length)
    |> validate_change(:url, &validate_url_field/2)
    |> validate_change(:file_mime_type, &validate_file_mime_type/2)
  end

  defp validate_url_field(:url, url) do
    if url_valid?(url), do: [], else: [url: "has invalid format"]
  end

  defp url_valid?(url) when is_binary(url) do
    uri = URI.parse(url)

    with true <- uri.scheme in ["http", "https"],
         host when is_binary(host) and host != "" <- uri.host,
         true <- host_valid?(host) do
      true
    else
      _ -> false
    end
  end

  defp url_valid?(_), do: false

  # Determined at compile time — allows localhost only in the test build.
  @allow_localhost Application.compile_env(:db, :env, :prod) == :test

  defp host_valid?(host) do
    cond do
      loopback_or_localhost_host?(host) -> @allow_localhost
      not String.contains?(host, ".") -> false
      true -> true
    end
  end

  defp loopback_or_localhost_host?(host) do
    host = String.downcase(host)

    host == "localhost" or
      String.ends_with?(host, ".localhost") or
      Regex.match?(~r/^127\./, host) or
      host in ["::1", "[::1]", "0:0:0:0:0:0:0:1"]
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
