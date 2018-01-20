defmodule DB.Repo.Migrations.AddTodayReputationGainToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :today_reputation_gain, :integer, default: 0, null: false
    end
  end
end
