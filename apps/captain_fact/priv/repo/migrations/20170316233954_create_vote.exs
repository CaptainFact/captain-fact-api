defmodule CaptainFact.Repo.Migrations.CreateVote do
  use Ecto.Migration

  def change do
    create table(:votes, primary_key: false) do
      add :value, :integer, null: false

      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :comment_id, references(:comments, on_delete: :delete_all), primary_key: true

      timestamps()
    end
    create unique_index(:votes, [:user_id, :comment_id], name: "user_comment_index")
  end
end
