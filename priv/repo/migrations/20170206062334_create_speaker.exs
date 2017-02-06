defmodule CaptainFact.Repo.Migrations.CreateSpeaker do
  use Ecto.Migration

  def change do
    create table(:speakers) do
      add :full_name, :string

      timestamps()
    end

  end
end
