defmodule CaptainFact.Web.Flag do
  use CaptainFact.Web, :model

  alias CaptainFact.Web.{Comment}

  @comment_type 1

  @types [:comment]
  @reasons [:spam, :bad_language, :harassment]
  @nb_reasons Enum.count(@reasons)

  schema "flags" do
    field :type, :integer
    field :reason, :integer
    field :entity_id, :integer
    belongs_to :source_user, CaptainFact.Web.User
    belongs_to :target_user, CaptainFact.Web.User

    timestamps()
  end

  @required_fields ~w(type reason entity_id source_user_id target_user_id)a

  @doc """
  Builds a changeset based on a `comment`
  """
  def changeset_comment(struct, comment = %Comment{}, otherParams = %{}) do
    params = Map.merge(%{
      entity_id: comment.id,
      type: @comment_type,
      target_user_id: comment.user_id
    }, otherParams)
    cast(struct, params, [:entity_id, :type, :reason, :target_user_id])
    |> validate_required(@required_fields)
    |> validate_reason()
  end

  def comment_type(), do: @comment_type

  def reason_str(reason_id),
    do: Atom.to_string(Enum.at(@reasons, reason_id - 1))

  def type_str(type_id),
    do: Atom.to_string(Enum.at(@types, type_id - 1))

  defp validate_reason(changeset) do
    validate_change changeset, :reason, fn :reason, reason ->
      if reason < 1 || reason > @nb_reasons, do: [reason: "Bad reason given"], else: []
    end
  end
end
