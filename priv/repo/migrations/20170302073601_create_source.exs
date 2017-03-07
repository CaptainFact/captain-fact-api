defmodule CaptainFact.Repo.Migrations.CreateSource do
  use Ecto.Migration

  def change do
    create table(:sources) do
      add :url, :string
      add :title, :string
      add :media, references(:medias, on_delete: :nothing)

      timestamps()
    end
    create index(:sources, [:media])

  end
end
