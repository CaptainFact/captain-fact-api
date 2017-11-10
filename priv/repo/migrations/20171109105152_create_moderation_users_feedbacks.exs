defmodule CaptainFact.Repo.Migrations.CreateModerationUsersFeedbacks do
  use Ecto.Migration

  def change do
    create table(:moderation_users_feedbacks) do
      add :feedback, :integer
      add :user_id, references(:users, on_delete: :nothing)
      add :action_id, references(:users_actions, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:moderation_users_feedbacks, [:user_id, :action_id])
  end
end
