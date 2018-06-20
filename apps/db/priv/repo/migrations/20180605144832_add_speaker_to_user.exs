defmodule DB.Repo.Migrations.AddSpeakerToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :speaker_id, references(:speakers, on_delete: :nilify_all), null: true, default: nil
    end
  end
end
