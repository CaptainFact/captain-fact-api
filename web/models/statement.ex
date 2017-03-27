defmodule CaptainFact.Statement do
  use CaptainFact.Web, :model

  schema "statements" do
    field :text, :string
    field :time, :integer

    belongs_to :video, CaptainFact.Video
    belongs_to :speaker, CaptainFact.Speaker
    has_many :comments, CaptainFact.Comment

    timestamps()
  end

  #TODO Add video to required fields
  @required_fields ~w(text time speaker_id)a

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
