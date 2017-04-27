defmodule CaptainFact.Source do
  use CaptainFact.Web, :model

  schema "sources" do
    field :url, :string
    field :title, :string
    field :language, :string
    field :site_name, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title, :language, :site_name])
    |> validate_required([:url])
    |> unique_constraint(:url)
    |> validate_format(:url, ~r/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/)
  end
end
