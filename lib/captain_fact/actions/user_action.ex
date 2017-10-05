defmodule CaptainFact.Actions.UserAction do
  use Ecto.Schema
  import Ecto.Changeset
  alias CaptainFact.Actions.UserAction
  alias CaptainFact.Accounts.User


  schema "users_actions" do
    belongs_to :user, User
    belongs_to :target_user, User

    field :context, :string
    field :type, :integer
    field :entity, :integer
    field :entity_id, :integer
    field :changes, :map

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(%UserAction{} = user_action, attrs) do
    user_action
    |> cast(attrs, [:context, :type, :entity, :entity_id, :changes])
    |> validate_required([:user_id, :type])
    |> cast_assoc(:user)
  end

  # Common actions
  def type(value) when is_integer(value), do: value
  def type(:create),    do: 1
  def type(:add),       do: 2
  def type(:update),    do: 3
  def type(:delete),    do: 4
  def type(:remove),    do: 5
  def type(:restore),   do: 6
  def type(:approve),   do: 7
  def type(:flag),      do: 8
  def type(:vote_up),   do: 9
  def type(:vote_down), do: 10
  def type(:self_vote), do: 11

  # Special actions
  def type(:email_verified), do: 100

  # Entities
  def entity(value) when is_integer(value), do: value
  def entity(:video),           do: 1
  def entity(:speaker),         do: 2
  def entity(:statement),       do: 3
  def entity(:comment),         do: 4
  def entity(:history_action),  do: 5

end
