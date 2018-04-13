defmodule DB.Schema.ModerationUserFeedback do
  use Ecto.Schema
  import Ecto.Changeset
  alias DB.Schema.ModerationUserFeedback


  schema "moderation_users_feedbacks" do
    field :value, :integer
    field :user_id, :id
    field :action_id, :id
    field :flag_reason, DB.Type.FlagReason

    timestamps()
  end

  @doc false
  def changeset(%ModerationUserFeedback{} = user_feedback, attrs) do
    user_feedback
    |> cast(attrs, [:value, :flag_reason])
    |> validate_required([:value, :action_id, :user_id, :flag_reason])
    |> validate_number(:value, greater_than_or_equal_to: -1, less_than_or_equal_to: 1)
  end
end
