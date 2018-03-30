defmodule DB.Schema.Source do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sources" do
    field :url, :string
    field :og_url, :string
    field :title, :string
    field :language, :string
    field :site_name, :string

    timestamps()
  end

  # Allow to add localhost urls as sources during tests
  @url_regex if Application.get_env(:db, :env) == :test,
    do: ~r/(^https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))|localhost/,
    else: ~r/^https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url])
    |> update_change(:url, &prepare_url/1)
    |> validate_required([:url])
    |> unique_constraint(:url)
    |> validate_format(:url, @url_regex)
  end

  def changeset_fetched(struct, params) do
    struct
    |> cast(params, [:og_url, :url, :title, :language, :site_name, :og_url])
    |> update_change(:url, &prepare_url/1)
    |> update_change(:og_url, &prepare_url/1)
    |> update_change(:title, &clean_and_truncate/1)
    |> update_change(:language, &String.trim/1)
    |> update_change(:site_name, &clean_and_truncate/1)
    |> validate_required([:url])
    |> unique_constraint(:url)
    |> validate_format(:url, @url_regex)
  end

  @regex_contains_http ~r/^https?:\/\//
  def prepare_url(str) do
    str = String.trim(str)
    if Regex.match?(@regex_contains_http, str),
      do: str, else: "https://" <>  str
  end

  defp clean_and_truncate(str) do
    if !String.valid?(str) do
      nil
    else
      str = DB.Utils.String.trim_all_whitespaces(str)
      if String.length(str) > 250,
         do: String.slice(str, 0, 250) <> "...",
         else: str
    end
  end
end
