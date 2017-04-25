defmodule CaptainFact.Video do
  use CaptainFact.Web, :model

  alias CaptainFact.{ VideoSpeaker, Statement, Speaker }

  schema "videos" do
    field :title, :string
    field :url, :string

    many_to_many :speakers, Speaker, join_through: VideoSpeaker
    has_many :statements, Statement

    timestamps()
  end

  def with_speakers(query) do
    from v in query, preload: [:speakers]
  end

  def with_statements(query) do
    from v in query, preload: [:statements]
  end

  def format_url(url) do
    url
    |> String.replace_prefix("http://", "https://")
    |> String.replace(~r/&.*/, "")
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:url, :title])
    |> validate_required([:url, :title])
    |> validate_length(:title, min: 5, max: 120)
    |> validate_format(:url, ~r/(?:youtube\.com\/\S*(?:(?:\/e(?:mbed))?\/|watch\/?\?(?:\S*?&?v\=))|youtu\.be\/)([a-zA-Z0-9_-]{6,11})/)
    |> unique_constraint(:url)
  end
end
