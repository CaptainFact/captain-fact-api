defmodule DB.Schema.UserAction do
  @moduledoc """
  Represent a user action. This is usefull to generate logs of all actions
  for a video, or all actions for a user without having to query multiple
  tables with complicated requests.

  This is also used by UserPermissions to check daily limitations.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias DB.Schema.{UserAction, User, Video, Speaker, Comment, Statement}

  schema "users_actions" do
    belongs_to(:user, User)
    belongs_to(:target_user, User)

    field(:type, DB.Type.UserActionType)
    field(:entity, :integer)
    field(:changes, :map)

    belongs_to(:video, Video)
    belongs_to(:statement, Statement)
    belongs_to(:comment, Comment)
    belongs_to(:speaker, Speaker)

    timestamps(updated_at: false)

    # Deprecated fields
    field(:context, :string)
    field(:entity_id, :integer)
  end

  @fields ~w(user_id target_user_id type entity changes video_id statement_id comment_id speaker_id)a

  @doc false
  def changeset(action = %UserAction{}, attrs) do
    action
    |> cast(attrs, @fields)
    |> update_change(:entity, &entity/1)
    |> cast_assoc(:user)
    |> cast_assoc(:target_user)
    |> validate_required([:user_id, :type, :entity])
  end

  @admin_fields @fields -- [:user_id]

  @doc """
  ⚠️ Admin-only function
  """
  def changeset_admin(action = %UserAction{}, attrs) do
    action
    |> cast(attrs, @admin_fields)
    |> update_change(:entity, &entity/1)
    |> cast_assoc(:target_user)
    |> validate_inclusion(:user, [nil])
    |> validate_required([:type, :entity])
  end

  # Entities
  def entity(value) when is_integer(value), do: value
  def entity(:video), do: 1
  def entity(:speaker), do: 2
  def entity(:statement), do: 3
  def entity(:comment), do: 4
  def entity(:fact), do: 5
  def entity(:user), do: 7
  # Deprecated. Can safelly be re-used
  def entity(:video_debate_action), do: 6

  @doc """
  Take a list of entities as atom, returns their equivalent as integer
  """
  @spec entities(list(:atom)) :: list(:integer)
  def entities(entities),
    do: Enum.map(entities, &UserAction.entity/1)
end
