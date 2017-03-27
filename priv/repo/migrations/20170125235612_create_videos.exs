defmodule CaptainFact.Repo.Migrations.CreateVideo do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :is_private, :boolean, default: false, null: false
      add :title, :string, null: false
      add :url, :string, null: false
      add :owner_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
    create index(:videos, [:owner_id])

  end
end
