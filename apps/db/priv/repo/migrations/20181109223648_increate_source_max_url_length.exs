defmodule DB.Repo.Migrations.IncreateSourceMaxUrlLength do
  use Ecto.Migration

  def up do
    alter table(:sources) do
      modify(:url, :string, size: 2048)
    end
  end

  def down do
    Ecto.Adapters.SQL.query!(DB.Repo, """
    DELETE FROM sources WHERE LENGTH(url) > 255;
    """)

    alter table(:sources) do
      modify(:url, :string)
    end
  end
end
