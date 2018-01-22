defmodule DB.Repo.Migrations.CreateFlag do
  use Ecto.Migration

  def change do
    create table(:flags) do
      add :type, :integer, null: false
      add :reason, :integer, null: false
      add :entity_id, :integer, null: false

      add :source_user_id, references(:users, on_delete: :delete_all), null: false
      add :target_user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
    create index(:flags, [:source_user_id])
    create index(:flags, [:target_user_id])
    create unique_index(:flags, [:source_user_id, :type, :entity_id])
  end
end
