defmodule CaptainFact.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :statement_id, references(:statements, on_delete: :delete_all), null: false
      add :source_id, references(:sources, on_delete: :nothing), null: true
      add :reply_to_id, references(:comments, on_delete: :delete_all), null: true

      add :text, :string
      add :approve, :boolean
      add :is_banned, :boolean, null: false, default: false

      timestamps()
    end
    create index(:comments, [:user_id])
    create index(:comments, [:statement_id], where: "is_banned = false")

  end
end
