defmodule DB.Repo.Migrations.CreateVideoSpeaker do
  use Ecto.Migration

  def change do
    create table(:videos_speakers, primary_key: false) do
      add :video_id, references(:videos, on_delete: :delete_all), primary_key: true
      add :speaker_id, references(:speakers, on_delete: :delete_all), primary_key: true

      timestamps()
    end
    create unique_index(:videos_speakers, [:video_id, :speaker_id], name: :videos_speakers_index)
  end
end
