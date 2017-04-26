defmodule CaptainFact.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :citext, null: false
      add :email, :citext, null: false
      add :name, :citext
      add :encrypted_password, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end
