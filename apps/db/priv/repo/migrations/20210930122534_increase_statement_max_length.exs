defmodule DB.Repo.Migrations.IncreaseStatementMaxLength do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      modify :text, :string, size: 280
    end
  end
end
