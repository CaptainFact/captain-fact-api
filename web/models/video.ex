defmodule CaptainFact.Video do
  use CaptainFact.Web, :model

  alias CaptainFact.{Video, User, VideoAdmin, Speaker, VideoSpeaker, Statement}

  schema "videos" do
    field :is_private, :boolean, default: false
    field :title, :string
    field :url, :string
    belongs_to :owner, User

    many_to_many :speakers, Speaker, join_through: VideoSpeaker
    many_to_many :admins, User, join_through: VideoAdmin,
      on_delete: :delete_all,
      on_replace: :delete
    has_many :statements, Statement

    timestamps()
  end

  def with_speakers(query) do
    from v in query, preload: [:speakers]
  end

  def with_statements(query) do
    from v in query, preload: [:statements]
  end

  def with_admins(query) do
    from v in query, preload: [:admins]
  end

  def is_admin(%Video{owner_id: id}, %User{id: id}), do: true
  def is_admin(%Video{admins: admins}, %User{id: id}), do: Enum.any?(admins, &(&1.id === id))
  def is_admin(_, _), do: false

  def has_access(%Video{is_private: false}, _user_id), do: true
  def has_access(video, user), do: is_admin(video, user)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:is_private, :url, :title])
    |> validate_required([:url, :title])
    |> validate_length(:title, min: 5, max: 120)
    |> validate_format(:url, ~r/(?:youtube\.com\/\S*(?:(?:\/e(?:mbed))?\/|watch\/?\?(?:\S*?&?v\=))|youtu\.be\/)([a-zA-Z0-9_-]{6,11})/)
  end
end
