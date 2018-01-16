defmodule CaptainFact.Repo.Migrations.AddSlugToSpeaker do
  use Ecto.Migration

  def change do
    alter table(:speakers) do
      add :slug, :string, null: true
    end

    create unique_index(:speakers, [:slug], where: "slug != NULL")
  end
end
