defmodule DB.Schema.Flag do
  use Ecto.Schema
  import Ecto.Changeset

  alias DB.Schema.{User, UserAction}

  schema "flags" do
    # Source user
    belongs_to(:source_user, User)
    belongs_to(:action, UserAction)
    field(:reason, DB.Type.FlagReason)
    timestamps()
  end

  @required_fields ~w(source_user_id action_id reason)a

  @doc """
  Builds a changeset based on an `UserAction`
  """
  def changeset(struct, params) do
    struct
    |> cast(params, [:action_id, :reason])
    |> validate_required(@required_fields)
  end
end
