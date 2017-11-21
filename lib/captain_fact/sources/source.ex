defmodule CaptainFact.Sources.Source do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sources" do
    field :url, :string
    field :title, :string
    field :language, :string
    field :site_name, :string

    timestamps()
  end

  @url_regex Application.get_env(:captain_fact, :source_url_regex)


  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title, :language, :site_name])
    |> update_change(:url, &prepare_url/1)
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
      str = StringUtils.trim_all_whitespaces(str)
      if String.length(str) > 250,
         do: String.slice(str, 0, 250) <> "...",
         else: str
    end
  end
end
