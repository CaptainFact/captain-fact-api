defmodule DB.Repo.Migrations.AddParentIdToCategories do
  use Ecto.Migration

  def change do
    alter table :categories do
      add :parent_id, references("categories"), null: true
    end
  end
end
