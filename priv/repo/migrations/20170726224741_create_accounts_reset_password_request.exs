defmodule CaptainFact.Repo.Migrations.CreateCaptainFact.Accounts.ResetPasswordRequest do
  use Ecto.Migration

  def change do
    create table(:accounts_reset_password_requests, primary_key: false) do
      add :token, :string, primary_key: true, null: false
      add :source_ip, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(updated_at: false)
    end
  end
end
