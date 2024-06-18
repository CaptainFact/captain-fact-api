defmodule DB.Schema.VideoCaption do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "videos_captions" do
    belongs_to(:video, DB.Schema.Video, primary_key: true)
    field(:raw, :string)
    field(:parsed, {:array, :map})
    field(:format, :string)

    timestamps()
  end

  @required_fields ~w(video_id raw parsed format)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
  end
end
