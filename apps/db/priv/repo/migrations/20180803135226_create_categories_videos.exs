defmodule DB.Repo.Migrations.CreateCategoriesVideos do
  use Ecto.Migration

  def change do
    create table(:categories_videos, primary_key: false) do
      add :category_id, references(:categories, on_delete: :delete_all), primary_key: true
      add :video_id, references(:videos, on_delete: :delete_all), primary_key: true

      timestamps()
    end

    create unique_index(:categories_videos, [:category_id, :video_id], name: :categories_videos_index)
  end
end
