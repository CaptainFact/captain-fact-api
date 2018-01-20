defmodule DB.Repo.Migrations.CreateUsersActionsReports do
  use Ecto.Migration

  def change do
    create table(:users_actions_reports) do
      add :analyser_id, :integer, null: false
      add :last_action_id, :integer, null: false
      add :status, :integer, null: false

      # Various stats
      add :nb_actions, :integer, null: true
      add :nb_entries_updated, :integer, null: true
      add :run_duration, :integer, null: true

      timestamps()
    end
  end
end
