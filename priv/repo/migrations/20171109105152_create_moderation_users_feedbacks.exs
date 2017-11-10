defmodule CaptainFact.Repo.Migrations.CreateModerationUsersFeedbacks do
  use Ecto.Migration

  def change do
    create table(:moderation_users_feedbacks) do
      add :feedback, :integer
      add :user_id, references(:users, on_delete: :delete_all)
      add :action_id, references(:users_actions, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:moderation_users_feedbacks, [:user_id, :action_id])
  end
end
