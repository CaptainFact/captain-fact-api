defmodule CaptainFact.Repo.Migrations.CreateStatement do
  use Ecto.Migration

  def change do
    StatementStatusEnum.create_type
    TruthinessEnum.create_type

    create table(:statements) do
      add :text, :string
      add :status, :statement_status_enum
      add :truthiness, :thruthiness_enum
      add :video_id, references(:videos, on_delete: :nothing)
      add :speaker_id, references(:speakers, on_delete: :nothing)

      timestamps()
    end
    create index(:statements, [:video_id])
    create index(:statements, [:speaker_id])

  end
end
