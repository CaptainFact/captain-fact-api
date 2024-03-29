defmodule DB.Repo.Migrations.CreatePostgresExtensions do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS citext;")
    execute("CREATE EXTENSION IF NOT EXISTS unaccent;")
  end
end
