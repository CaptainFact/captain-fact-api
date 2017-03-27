defmodule CaptainFact.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :statement_id, references(:statements, on_delete: :delete_all), null: false

      add :text, :string
      add :approve, :boolean

      add :source_url, :string
      add :source_title, :string
      add :media_id, references(:medias, on_delete: :nilify_all)

      timestamps()
    end
    create index(:comments, [:user_id])
    create index(:comments, [:statement_id])

  end
end
