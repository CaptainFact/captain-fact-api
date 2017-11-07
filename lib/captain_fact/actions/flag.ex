defmodule CaptainFact.Actions.Flag do
  use Ecto.Schema
  import Ecto.Changeset

  alias CaptainFact.Actions.UserAction

  @reasons [:spam, :bad_language, :harassment]
  @nb_reasons Enum.count(@reasons)

  schema "flags" do
    belongs_to :source_user, User # Source user
    belongs_to :action, UserAction
    field :reason, :integer
    timestamps()
  end

  @required_fields ~w(source_user_id action_id reason)a

  @doc"""
  Convert reason to a string (usefull for dev)
  """
  def reason_str(reason_id), do: Atom.to_string(Enum.at(@reasons, reason_id - 1))

  @doc"""
  Builds a changeset based on an `UserAction`
  """
  def changeset(struct, params) do
    cast(struct, params, [:action_id, :reason])
    |> validate_required(@required_fields)
    |> validate_reason()
  end

  defp validate_reason(changeset) do
    validate_change changeset, :reason, fn :reason, reason ->
      if reason < 1 || reason > @nb_reasons, do: [reason: "Bad reason given"], else: []
    end
  end
end
