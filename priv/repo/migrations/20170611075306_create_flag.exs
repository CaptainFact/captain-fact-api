defmodule CaptainFact.Repo.Migrations.CreateFlag do
  use Ecto.Migration

  def change do
    create table(:flags) do
      add :type, :integer, null: false
      add :entity_id, :integer, null: false
      add :source_user_id, references(:users, on_delete: :nothing), null: false
      add :target_user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end
    create index(:flags, [:source_user_id])
    create index(:flags, [:target_user_id])
    create unique_index(:flags, [:type, :entity_id])
  end
end
