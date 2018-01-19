defmodule DB.Schema.UserFeedback do
  use Ecto.Schema
  import Ecto.Changeset
  alias DB.Schema.UserFeedback


  schema "moderation_users_feedbacks" do
    field :value, :integer
    field :user_id, :id
    field :action_id, :id

    timestamps()
  end

  @doc false
  def changeset(%UserFeedback{} = user_feedback, attrs) do
    user_feedback
    |> cast(attrs, [:value])
    |> validate_required([:value, :action_id, :user_id])
    |> validate_number(:value, greater_than_or_equal_to: -1, less_than_or_equal_to: 1)
  end
end
