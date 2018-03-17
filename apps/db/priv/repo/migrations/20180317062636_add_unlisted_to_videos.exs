defmodule DB.Repo.Migrations.AddUnlistedToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :unlisted, :boolean, default: false, null: false
    end
  end
end
