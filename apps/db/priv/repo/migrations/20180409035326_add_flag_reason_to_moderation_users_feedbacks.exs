defmodule DB.Repo.Migrations.AddFlagReasonToModerationUsersFeedback do
  use Ecto.Migration
  import Ecto.Query
  alias DB.Schema.UserAction


  def change do
    # Delete all existing feedbacks
    DB.Repo.delete_all(DB.Schema.ModerationUserFeedback, log: false)

    # Add flag reason to feedbacks
    alter table("moderation_users_feedbacks") do
      add :flag_reason, :integer, null: false
    end

    # We also changed the way confirmed_email actions are recorded, invert
    # source_user_id and target_user_id
    UserAction
    |> where([a], a.type == ^UserAction.type(:email_confirmed))
    |> where([a], is_nil(a.target_user_id))
    |> select([:id, :type, :user_id, :target_user_id])
    |> DB.Repo.all()
    |> Enum.map(&invert_source_and_target_users/1)
  end

  defp invert_source_and_target_users(action = %{user_id: src_usr_id}) do
    action
    |> Ecto.Changeset.change(user_id: nil, target_user_id: src_usr_id)
    |> DB.Repo.update(log: false)
  end
end
