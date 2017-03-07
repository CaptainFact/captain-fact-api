defmodule CaptainFact.Speaker do
  use CaptainFact.Web, :model

  schema "speakers" do
    field :full_name, :string
    field :title, :string

    has_many :statements, CaptainFact.Statement
    many_to_many :videos, CaptainFact.Video, join_through: "videos_speakers"
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:full_name, :title])
    |> validate_required([:full_name])
  end
end
