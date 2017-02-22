defmodule CaptainFact.VideoSpeaker do
  use CaptainFact.Web, :model

  schema "videos_speakers" do
    field :video_id, :integer
    field :speaker_id, :integer

    timestamps()
  end

  @required_fields ~w(video_id speaker_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
