defmodule CaptainFact.Repo.Migrations.RenameFlagTypeToFlagEntityAndRemoveUnusedIndexes do
  use Ecto.Migration

  def change do
    rename table(:flags), :type, to: :entity

    # Rename unique index
    drop unique_index(:flags, [:source_user_id, :type, :entity_id])
    create unique_index(:flags, [:source_user_id, :entity, :entity_id])

    # Remove unused indexes
    drop index(:flags, [:source_user_id])
    drop index(:flags, [:target_user_id])
  end
end
