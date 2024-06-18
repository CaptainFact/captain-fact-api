defmodule DB.Repo.Migrations.UpdateVideoCaptions do
  use Ecto.Migration

  def up do
    # Delete all values (there are none in prod)
    execute("DELETE FROM videos_captions")

    # Drop column :content in favor of raw + parsed
    alter table(:videos_captions) do
      remove(:content)
      add(:raw, :text, null: false)
      add(:parsed, {:array, :map}, null: false)
    end
  end

  def down do
    # Drop raw + parsed in favor of :content
    alter table(:videos_captions) do
      remove(:raw)
      remove(:parsed)
      add(:content, :text, null: false)
    end
  end
end
