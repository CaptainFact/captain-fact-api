defmodule CaptainFact.Repo.Migrations.DeleteAchievements do
  use Ecto.Migration

  def change do
    drop table(:achievements)
  end
end
