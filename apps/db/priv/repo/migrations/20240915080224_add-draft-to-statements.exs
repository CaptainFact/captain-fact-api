defmodule :"Elixir.DB.Repo.Migrations.Add-draft-to-statements" do
  use Ecto.Migration

  def change do
    alter table(:statements) do
      add :is_draft, :boolean, default: false, null: false
    end
  end
end
