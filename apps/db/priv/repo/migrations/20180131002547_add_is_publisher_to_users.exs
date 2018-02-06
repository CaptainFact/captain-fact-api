defmodule DB.Repo.Migrations.AddIsPublisherToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_publisher, :boolean, default: false, null: false
    end
  end
end
