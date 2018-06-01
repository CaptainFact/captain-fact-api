defmodule DB.Repo.Migrations.AddIsPartnerToVideo do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :is_partner, :boolean, default: false, null: false
    end
  end
end
