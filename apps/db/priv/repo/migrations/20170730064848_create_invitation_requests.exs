defmodule DB.Repo.Migrations.CreateInvitationRequests do
  use Ecto.Migration

  def change do
    create table(:invitation_requests) do
      add :email, :string, null: true
      add :token, :string, null: true
      add :invitation_sent, :boolean, default: false, null: false
      add :invited_by_id, references(:users, on_delete: :nilify_all), null: true

      timestamps()
    end

    create unique_index(:invitation_requests, [:email])
  end
end
