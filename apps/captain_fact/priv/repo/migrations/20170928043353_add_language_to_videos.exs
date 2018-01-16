defmodule CaptainFact.Repo.Migrations.AddLanguageToVideos do
  use Ecto.Migration

  def change do
    alter table(:videos) do
      add :language, :string, size: 2
    end
    create index(:videos, :language)
  end
end
