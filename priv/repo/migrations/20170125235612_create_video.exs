defmodule CaptainFact.Repo.Migrations.CreateVideo do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :is_private, :boolean, default: false, null: false
      add :title, :string, null: false
      add :url, :string
      add :owner, references(:users, on_delete: :delete_all)

      timestamps()
    end
    create index(:videos, [:owner])

  end
end
