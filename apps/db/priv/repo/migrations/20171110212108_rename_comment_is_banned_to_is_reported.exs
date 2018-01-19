defmodule DB.Repo.Migrations.RenameCommentIsBannedToIsReported do
  use Ecto.Migration

  def change do
    drop index(:comments, [:statement_id], where: "is_banned = false")
    rename table(:comments), :is_banned, to: :is_reported
    create index(:comments, [:statement_id])
  end
end
