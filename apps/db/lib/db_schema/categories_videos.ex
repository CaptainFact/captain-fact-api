defmodule DB.Schema.CategoriesVideos do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "categories_videos" do
    belongs_to(:video, DB.Schema.Video, primary_key: true)
    belongs_to(:category, DB.Schema.Category, primary_key: true)

    timestamps()
  end

  @required_fields ~w(video_id category_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`
  """
  @spec changeset(%__MODULE__{} | Ecto.Changeset.t)::Ecto.Changeset.t
  def changeset(struct, params \\ []) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:video, name: :categories_video_pkey)
  end
end
