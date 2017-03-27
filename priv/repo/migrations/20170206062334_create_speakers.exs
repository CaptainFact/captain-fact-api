defmodule CaptainFact.Repo.Migrations.CreateSpeaker do
  use Ecto.Migration

  def change do
    create table(:speakers) do
      add :full_name, :string, null: false
      add :title, :string
      add :is_user_defined, :boolean, null: false
      
      timestamps()
    end

  end
end
