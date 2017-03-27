defmodule CaptainFact.Repo.Migrations.CreateVideosSpeakers do
  use Ecto.Migration

  def change do
    create table(:videos_speakers) do
      add :video_id, references(:videos, on_delete: :delete_all), null: false
      add :speaker_id, references(:speakers, on_delete: :delete_all), null: false

      timestamps()
    end
    create index(:videos_speakers, [:video_id])
    create index(:videos_speakers, [:speaker_id])
    # TODO Unique index + composite primary keys
  end
end
