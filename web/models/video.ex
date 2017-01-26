defmodule CaptainFact.Video do
  use CaptainFact.Web, :model

  schema "videos" do
    field :is_private, :boolean, default: false
    field :title, :string
    field :url, :string
    belongs_to :owner, CaptainFact.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:is_private, :url])
    |> validate_required([:url, :title])
  end
end
