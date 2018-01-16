defmodule CaptainFact.Repo.Migrations.CreateVideoDebateAction do
  use Ecto.Migration

  def change do
    create table(:video_debate_actions) do
      add :user_id, references(:users, on_delete: :nothing), null: true
      add :video_id, references(:videos, on_delete: :nothing), null: false
      add :entity, :string, null: false
      add :entity_id, :integer, null: false
      add :type, :string, null: false
      add :changes, :map, null: true

      timestamps(updated_at: false)
    end
    create index(:video_debate_actions, [:user_id])
    create index(:video_debate_actions, [:video_id])
    create index(:video_debate_actions, [:entity, :entity_id])
  end
end
