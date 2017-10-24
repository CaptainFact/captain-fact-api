defmodule CaptainFact.Actions.Flag do
  use Ecto.Schema
  import Ecto.Changeset

  alias CaptainFact.Comments.Comment

  @reasons [:spam, :bad_language, :harassment]
  @nb_reasons Enum.count(@reasons)

  schema "flags" do
    field :entity, :integer
    field :entity_id, :integer
    field :reason, :integer
    belongs_to :source_user, CaptainFact.Accounts.User
    belongs_to :target_user, CaptainFact.Accounts.User
    timestamps()
  end

  @required_fields ~w(entity reason entity_id source_user_id target_user_id)a

  @doc """
  Builds a changeset based on a `comment`
  """
  def changeset_comment(struct, comment = %Comment{}, otherParams = %{}) do
    params = Map.merge(%{
      entity_id: comment.id,
      entity: CaptainFact.Actions.UserAction.entity(:comment),
      target_user_id: comment.user_id
    }, otherParams)
    cast(struct, params, [:entity_id, :entity, :reason, :target_user_id])
    |> validate_required(@required_fields)
    |> validate_reason()
  end

  def reason_str(reason_id),
    do: Atom.to_string(Enum.at(@reasons, reason_id - 1))

  defp validate_reason(changeset) do
    validate_change changeset, :reason, fn :reason, reason ->
      if reason < 1 || reason > @nb_reasons, do: [reason: "Bad reason given"], else: []
    end
  end
end
