defmodule CaptainFact.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION citext;")

    create table(:users) do
      add :username, :citext
      add :email, :citext
      add :name, :string
      add :encrypted_password, :string

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
  end
end
