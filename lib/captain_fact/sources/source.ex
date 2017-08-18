defmodule CaptainFact.Sources.Source do
  use CaptainFactWeb, :model

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
    |> validate_format(:url, @url_regex)
  end
end
