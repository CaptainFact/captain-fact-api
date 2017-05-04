defmodule CaptainFact.VideoDebateAction do
  use CaptainFact.Web, :model

  schema "video_debate_actions" do
    belongs_to :user, CaptainFact.User
    belongs_to :video, CaptainFact.Video

    field :entity, :string
    field :entity_id, :integer

    field :type, :string
    field :changes, :map

    timestamps(updated_at: false)
  end

  def with_user(query) do
    from a in query, preload: :user
  end

  @required_fields ~w(user_id video_id entity entity_id type)a
  @optional_fields ~w(changes)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:entity, ["statement", "speaker"])
    |> validate_inclusion(:type, ["create", "remove", "update", "delete", "add", "restore"])
    |> validate_changes()
  end

  defp validate_changes(changeset) do
    type = get_field(changeset, :type)
    changes = get_field(changeset, :changes)
    if type in ~w(create add update) do
      must_have_changes(changeset, changes)
    else
      must_not_have_changes(changeset, changes)
    end
  end

  defp must_have_changes(changeset, nil),
  do: add_error(changeset, :changes, "must have changes")
  defp must_have_changes(changeset, _), do: changeset

  defp must_not_have_changes(changeset, nil), do: changeset
  defp must_not_have_changes(changeset, _),
  do: add_error(changeset, :changes, "cannot have changes")
end
