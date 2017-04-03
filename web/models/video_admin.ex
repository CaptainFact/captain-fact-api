defmodule CaptainFact.VideoAdmin do
  use CaptainFact.Web, :model

  @primary_key false
  schema "videos_admins" do
    belongs_to :video, CaptainFact.Video, primary_key: true
    belongs_to :user, CaptainFact.User, primary_key: true

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :video_id])
    |> validate_required([:user_id, :video_id])
    |> unique_constraint(:video, name: :videos_admins_pkey)
  end
end
