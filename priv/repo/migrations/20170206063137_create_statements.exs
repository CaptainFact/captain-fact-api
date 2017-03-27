defmodule CaptainFact.Repo.Migrations.CreateStatement do
  use Ecto.Migration

  def change do
    create table(:statements) do
      add :text, :string, null: false
      add :time, :integer, null: false
      add :video_id, references(:videos, on_delete: :delete_all), null: false
      add :speaker_id, references(:speakers, on_delete: :delete_all), null: false

      timestamps()
    end
    create index(:statements, [:video_id])
    create index(:statements, [:speaker_id])

  end
end
