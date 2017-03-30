defmodule CaptainFact.Repo.Migrations.CreateVideoAdmin do
  use Ecto.Migration

  def change do
    create table(:videos_admins, primary_key: false) do
      add :video_id, references(:videos, on_delete: :delete_all), primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true

      timestamps()
    end
    create unique_index(:videos_admins, [:user_id, :video_id], name: "video_admin_index")
  end
end
