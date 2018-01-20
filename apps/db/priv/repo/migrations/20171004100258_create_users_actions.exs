defmodule DB.Repo.Migrations.CreateUsersActions do
  use Ecto.Migration

  def change do
    create table(:users_actions) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :target_user_id, references(:users, on_delete: :nothing), null: true

      add :type, :integer, null: false
      add :entity, :integer, null: false
      add :context, :string, null: true
      add :entity_id, :integer, null: true
      add :changes, :map, null: true

      timestamps(updated_at: false)
    end

    create index(:users_actions, [:user_id])
    create index(:users_actions, [:context])
  end
end
