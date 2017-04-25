defmodule CaptainFact.Repo.Migrations.CreateVideo do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :url, :string, null: false
      add :title, :string, null: false

      timestamps()
    end
    create unique_index(:videos, [:url])
  end
end
