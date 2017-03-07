defmodule CaptainFact.Media do
  use CaptainFact.Web, :model

  schema "medias" do
    field :name, :string
    field :url_pattern, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :url_pattern])
    |> validate_required([:name, :url_pattern])
  end
end
