defmodule CaptainFact.Moderation.UserFeedback do
  use Ecto.Schema
  import Ecto.Changeset
  alias CaptainFact.Moderation.UserFeedback


  schema "moderation_users_feedbacks" do
    field :feedback, :integer
    field :user_id, :id
    field :action_id, :id

    timestamps()
  end

  @doc false
  def changeset(%UserFeedback{} = user_feedback, attrs) do
    user_feedback
    |> cast(attrs, [:feedback])
    |> validate_required([:feedback, :action_id, :user_id])
    |> validate_number(:feedback, greater_than_or_equal_to: -1, less_than_or_equal_to: 1)
  end
end
