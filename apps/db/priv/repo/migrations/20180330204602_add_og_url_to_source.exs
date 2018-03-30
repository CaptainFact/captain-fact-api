defmodule DB.Repo.Migrations.AddOgUrlToSource do
  use Ecto.Migration

  def change do
    alter table(:sources) do
      add :og_url, :string, default: nil, null: true
    end
  end
end
