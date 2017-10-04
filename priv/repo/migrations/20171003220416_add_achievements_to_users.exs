defmodule CaptainFact.Repo.Migrations.AddAchievementsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :achievements, {:array, :integer}, default: [], null: false
    end
  end
end
