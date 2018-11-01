defmodule DB.Repo.Migrations.CreateVideoCaptions do
  use Ecto.Migration

  def change do
    create table(:videos_captions) do
      add(:video_id, references(:videos, on_delete: :delete_all))
      add(:content, :text, null: false)
      add(:format, :string, null: false)
      timestamps()
    end

    create(index(:videos_captions, [:video_id]))
  end
end
