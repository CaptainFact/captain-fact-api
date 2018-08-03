defmodule DB.Repo.Migrations.MakeSpeakerSlugCaseInsensitive do
  use Ecto.Migration

  def up do
    alter table("speakers") do
      modify :slug, :citext
    end
  end

  def down do
    alter table("speakers") do
      modify :slug, :string
    end
  end
end
