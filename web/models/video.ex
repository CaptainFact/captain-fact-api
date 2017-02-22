defmodule CaptainFact.Video do
  use CaptainFact.Web, :model

  schema "videos" do
    field :is_private, :boolean, default: false
    field :title, :string
    field :url, :string
    belongs_to :owner, CaptainFact.User

    many_to_many :speakers, CaptainFact.Speaker, join_through: "videos_speakers"
    has_many :statements, CaptainFact.Statement

    timestamps()
  end

  def with_speakers(query) do
    from v in query, preload: [:speakers]
  end

  def with_statements(query) do
    from v in query, preload: [:statements]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:is_private, :url, :title])
    |> validate_required([:url, :title])
    |> validate_length(:title, min: 5, max: 50)
    # TODO: Validate URL format
  end
end
