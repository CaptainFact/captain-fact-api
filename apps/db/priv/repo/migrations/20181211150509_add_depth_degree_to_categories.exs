defmodule DB.Repo.Migrations.AddDepthDegreeToCategories do
  use Ecto.Migration

  def change do
    alter table :categories do
      add :depth_degree, :integer
    end
  end
end
