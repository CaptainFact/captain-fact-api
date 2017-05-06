defmodule CaptainFact.Repo.Migrations.CreateStatement do
  use Ecto.Migration

  def change do
    create table(:statements) do
      add :text, :string, null: false
      add :time, :integer, null: false
      add :is_removed, :boolean, null: false, default: false

      add :video_id, references(:videos), null: false
      add :speaker_id, references(:speakers), null: true

      timestamps()
    end
    create index(:statements, [:video_id], where: "is_removed = false")
    create index(:statements, [:speaker_id], where: "is_removed = false")

  end
end
