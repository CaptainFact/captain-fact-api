defmodule CaptainFact.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :citext, null: false
      add :email, :citext, null: false
      add :encrypted_password, :string, null: false
      add :name, :citext, null: true
      add :picture_url, :string, null: true
      add :reputation, :integer, null: false, default: 0

      # Social networks profiles
      add :fb_user_id, :string, null: true

      # Email confirmation
      add :email_confirmed, :boolean, null: false, default: false
      add :email_confirmation_token, :string, null: true

      # Reset password
      add :reset_password_confirmation_token, :string, null: true
      add :reset_password_request_time, :utc_datetime, null: true

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create unique_index(:users, [:fb_user_id])
  end
end
