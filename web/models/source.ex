defmodule CaptainFact.Source do
  use CaptainFact.Web, :model

  schema "sources" do
    field :url, :string
    field :title, :string
    belongs_to :media, CaptainFact.Media

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title])
    |> validate_required([:url, :title])
  end
end
