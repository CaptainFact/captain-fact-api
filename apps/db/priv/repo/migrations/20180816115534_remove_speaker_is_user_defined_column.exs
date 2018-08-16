defmodule DB.Repo.Migrations.RemoveSpeakerIsUserDefinedColumn do
  use Ecto.Migration

  def up do
    # Drop indexes
    drop(index(:speakers, :full_name))
    drop(index(:speakers, :wikidata_item_id))
    drop(unique_index(:speakers, :slug))

    # Remove column
    alter table(:speakers) do
      remove(:is_user_defined)
      remove(:is_removed)
    end

    # Re-create indexes
    create index(:speakers, :full_name)
    create unique_index(:speakers, :wikidata_item_id)
    create unique_index(:speakers, :slug, where: "slug IS NOT NULL")
  end

  def down do
    # Drop indexes
    drop(index(:speakers, :full_name))
    drop(index(:speakers, :wikidata_item_id))
    drop(unique_index(:speakers, :slug))

    # Re-add columns
    alter table(:speakers) do
      add(:is_user_defined, :boolean, null: false, default: true)
      add :is_removed, :boolean, null: false, default: false
    end

    # Re-create indexes
    create index(:speakers, :full_name, where: "is_user_defined = false")
    create unique_index(:speakers, :wikidata_item_id, where: "is_user_defined = false")
    create unique_index(:speakers, :slug, where: "slug IS NOT NULL")
  end
end
