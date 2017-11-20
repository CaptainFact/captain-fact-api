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
    |> validate_required([:url])
    |> unique_constraint(:url)
    |> update_change(:url, &prepare_url/1)
    |> validate_format(:url, @url_regex)
  end

  @regex_contains_http ~r/^https?:\/\//
  def prepare_url(str) do
    str = String.trim(str)
    if Regex.match?(@regex_contains_http, str),
      do: str, else: "https://" <>  str
  end
end
