defmodule DB.Repo.Migrations.AddCompletedOnboardingToUsers do
  use Ecto.Migration

  def up do
    alter table "users" do
      add :completed_onboarding_steps, {:array, :integer}, null: false, default: []
    end
  end

  def down do
    alter table "users" do
      remove :completed_onboarding_steps
    end
  end
end
