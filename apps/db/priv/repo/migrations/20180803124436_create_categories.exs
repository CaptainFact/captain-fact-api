defmodule DB.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table "categories" do
      # 150 is max size for Youtube playlist title maybe too much ?
      add(:title, :string, null: false, size: 150)

      timestamps()
    end
  end
end
