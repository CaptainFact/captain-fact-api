defmodule DB.Repo.Migrations.CreateVideo do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :provider, :string, null: false
      add :provider_id, :string, null: false
      add :title, :string, null: false

      timestamps()
    end
    create unique_index(:videos, [:provider, :provider_id])
  end
end
