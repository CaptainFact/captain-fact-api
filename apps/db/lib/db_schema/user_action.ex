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

    field(:type, :integer)
    field(:entity, :integer)
    field(:changes, :map)

    # Deprecated fields
    field(:entity_id, :integer)
    field(:context, :string)

    belongs_to(:video, Video)
    belongs_to(:statement, Statement)
    belongs_to(:comment, Comment)
    belongs_to(:speaker, Speaker)

    timestamps(updated_at: false)
  end

  @fields ~w(user_id target_user_id type entity changes video_id statement_id comment_id speaker_id)a

  @doc false
  def changeset(action = %UserAction{}, attrs) do
    action
    |> cast(attrs, @fields)
    |> update_change(:entity, &entity/1)
    |> update_change(:type, &type/1)
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
    |> update_change(:type, &type/1)
    |> cast_assoc(:target_user)
    |> validate_inclusion(:user, [nil])
    |> validate_required([:type, :entity])
  end

  # Common actions
  def type(value) when is_integer(value), do: value
  def type(:create), do: 1
  def type(:remove), do: 2
  def type(:update), do: 3
  def type(:delete), do: 4
  def type(:add), do: 5
  def type(:restore), do: 6
  def type(:approve), do: 7
  def type(:flag), do: 8
  # Voting stuff
  def type(:vote_up), do: 9
  def type(:vote_down), do: 10
  def type(:self_vote), do: 11
  def type(:revert_vote_up), do: 12
  def type(:revert_vote_down), do: 13
  def type(:revert_self_vote), do: 14
  # Bans - See DB.Type.FlagReason for labels
  def type(:action_banned_bad_language), do: 21
  def type(:action_banned_spam), do: 22
  def type(:action_banned_irrelevant), do: 23
  def type(:action_banned_not_constructive), do: 24
  # Special actions
  def type(:email_confirmed), do: 100
  def type(:collective_moderation), do: 101
  # Deprecated. Can safelly be re-used
  def type(:action_banned), do: 102
  def type(:abused_flag), do: 103
  def type(:confirmed_flag), do: 104
  def type(:social_network_linked), do: 105

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
