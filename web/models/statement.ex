defmodule CaptainFact.Statement do
  use CaptainFact.Web, :model

  schema "statements" do
    field :text, :string
    field :time, :integer

    belongs_to :video, CaptainFact.Video
    belongs_to :speaker, CaptainFact.Speaker
    
    has_many :comments, CaptainFact.Comment, on_delete: :delete_all

    timestamps()
  end

  @required_fields ~w(text time speaker_id video_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:time, greater_than_or_equal_to: 0)
    |> validate_length(:text, min: 10, max: 240)
    |> cast_assoc(:speaker)
  end
end
