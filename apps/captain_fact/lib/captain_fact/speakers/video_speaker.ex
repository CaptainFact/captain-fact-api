defmodule CaptainFact.Speakers.VideoSpeaker do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "videos_speakers" do
    belongs_to :video, CaptainFact.Videos.Video, primary_key: true
    belongs_to :speaker, CaptainFact.Speakers.Speaker, primary_key: true

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
    |> unique_constraint(:video, name: :videos_speakers_pkey)
  end
end
