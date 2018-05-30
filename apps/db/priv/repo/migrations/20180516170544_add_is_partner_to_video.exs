defmodule DB.Repo.Migrations.AddIsPartnerToVideo do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :is_partner, :boolean, default: false, null: false
    end

    # Move all existing videos to "partners"
    DB.Repo.update_all(DB.Schema.Video, set: [is_partner: true])
  end
end
