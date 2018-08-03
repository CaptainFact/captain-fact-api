defmodule DB.Repo.Migrations.CreateCategoriesVideos do
  use Ecto.Migration

  def change do
    create table("categories_videos") do
      add :category_id, references "categories"
      add :video_id, references "videos"
    end
  end
end
