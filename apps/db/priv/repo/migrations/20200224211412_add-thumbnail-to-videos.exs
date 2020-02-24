defmodule :"Elixir.DB.Repo.Migrations.Add-thumbnail-to-videos" do
  use Ecto.Migration

  def up do
    # Add new columns
    alter table(:videos) do
      add(:thumbnail, :string, null: true)
    end

    flush()

    Ecto.Adapters.SQL.query!(DB.Repo, """
    UPDATE videos
    SET thumbnail = 'https://img.youtube.com/vi/' || youtube_id || '/hqdefault.jpg'
    WHERE youtube_id IS NOT NULL;
    """)
  end

  def down do
    # Remove columns
    alter table(:videos) do
      remove(:thumbnail)
    end
  end
end
