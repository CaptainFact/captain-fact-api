defmodule CaptainFact.Repo.Migrations.CreateStatement do
  use Ecto.Migration

  def change do
    create table(:statements) do
      add :text, :string, null: false
      add :time, :integer, null: false
      add :is_deleted, :boolean, null: false, default: false

      add :video_id, references(:videos, on_delete: :delete_all), null: false
      add :speaker_id, references(:speakers, on_delete: :delete_all), null: false

      timestamps()
    end
    create index(:statements, [:video_id], where: "is_deleted = false")
    create index(:statements, [:speaker_id], where: "is_deleted = false")

  end
end
