defmodule CaptainFact.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements) do
      add :slug, :string
      add :rarity, :integer

      timestamps()
    end

    create unique_index(:achievements, [:slug])
  end
end
