defmodule DB.Repo.Migrations.AddLocaleToInvitationRequest do
  use Ecto.Migration

  def change do
    alter table(:invitation_requests) do
      add :locale, :string, null: false, default: "en"
    end
  end
end
