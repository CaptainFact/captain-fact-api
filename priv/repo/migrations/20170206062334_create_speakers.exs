defmodule CaptainFact.Repo.Migrations.CreateSpeaker do
  use Ecto.Migration

  def change do
    create table(:speakers) do
      add :full_name, :string
      add :title, :string
      add :is_user_defined, :boolean

      timestamps()
    end

  end
end
