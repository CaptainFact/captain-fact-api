defmodule DB.Schema.UserAction do
  use Ecto.Schema
  import Ecto.Changeset

  alias DB.Schema.{UserAction, User, Video}


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
    |> cast(attrs, [:context, :type, :entity, :entity_id, :changes, :user_id, :target_user_id])
    |> validate_required([:user_id, :type])
    |> cast_assoc(:user)
    |> cast_assoc(:target_user)
    |> update_change(:entity, &entity/1)
    |> update_change(:type, &type/1)
  end

  @doc"""
  ⚠️ Admin-only function
  """
  def admin_changeset(%UserAction{} = user_action, attrs) do
    user_action
    |> cast(attrs, [:context, :type, :entity, :entity_id, :changes, :target_user_id])
    |> validate_required([:type])
    |> validate_inclusion(:user, [nil])
    |> cast_assoc(:target_user)
    |> update_change(:entity, &entity/1)
    |> update_change(:type, &type/1)
  end

  # Common actions
  def type(value) when is_integer(value), do: value
  def type(:create),            do: 1
  def type(:remove),            do: 2
  def type(:update),            do: 3
  def type(:delete),            do: 4
  def type(:add),               do: 5
  def type(:restore),           do: 6
  def type(:approve),           do: 7
  def type(:flag),              do: 8
  # Voting stuff
  def type(:vote_up),           do: 9
  def type(:vote_down),         do: 10
  def type(:self_vote),         do: 11
  def type(:revert_vote_up),    do: 12
  def type(:revert_vote_down),  do: 13
  def type(:revert_self_vote),  do: 14
  # Bans - See DB.Type.FlagReason for labels
  def type(:action_banned_bad_language),      do: 21
  def type(:action_banned_spam),              do: 22
  def type(:action_banned_irrelevant),        do: 23
  def type(:action_banned_not_constructive),  do: 24
  # Special actions
  def type(:email_confirmed),       do: 100
  def type(:collective_moderation), do: 101
  def type(:action_banned),         do: 102 # Deprecated. Can safelly be re-used
  def type(:abused_flag),           do: 103
  def type(:confirmed_flag),        do: 104
  def type(:social_network_linked), do: 105

  # Entities
  def entity(value) when is_integer(value), do: value
  def entity(:video),                 do: 1
  def entity(:speaker),               do: 2
  def entity(:statement),             do: 3
  def entity(:comment),               do: 4
  def entity(:fact),                  do: 5
  def entity(:video_debate_action),   do: 6 # Deprecated. Can safelly be re-used
  def entity(:user),                  do: 7

  # Context helpers
  def video_debate_context(%Video{id: id}), do: "VD:#{id}"
  def video_debate_context(video_id), do: "VD:#{video_id}"
  def moderation_context(nil), do: "MD"
  def moderation_context(old_context) when is_binary(old_context), do: "MD:#{old_context}"
end
