defmodule CaptainFact.Repo.Migrations.CreateSource do
  use Ecto.Migration

  def change do
    create table(:sources) do
      add :url, :string, null: false
      add :title, :string, null: true
      add :language, :string, null: true
      add :site_name, :string, null: true

      timestamps()
    end
    create unique_index(:sources, :url)
  end
end
