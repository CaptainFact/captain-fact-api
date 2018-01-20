defmodule DB.Repo.Migrations.CreatePostgresExtensions do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION citext;")
    execute("CREATE EXTENSION unaccent;")
  end
end
