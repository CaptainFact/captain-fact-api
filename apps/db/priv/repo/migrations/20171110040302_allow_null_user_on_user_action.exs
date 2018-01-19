defmodule DB.Repo.Migrations.AllowNullUserOnUserAction do
  @moduledoc"""
  This migration allow for null value in user_id which will represent an admin action
  """

  use Ecto.Migration

  def change do
    alter table(:users_actions) do
      # No need to use a reference user as it is already referenced by previous migration. Referencing again
      # fails as constraint already exists
      modify :user_id, :integer, null: true
    end
  end
end
