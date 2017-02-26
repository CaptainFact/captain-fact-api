defmodule CaptainFact.Statement do
  use CaptainFact.Web, :model

  schema "statements" do
    field :text, :string
    field :time, :integer
    field :status, StatementStatusEnum
    belongs_to :video, CaptainFact.Video
    belongs_to :speaker, CaptainFact.Speaker

    timestamps()
  end

  @required_fields ~w(text status time speaker_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:speaker)
  end
end
