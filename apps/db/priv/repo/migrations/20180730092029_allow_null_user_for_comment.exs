defmodule DB.Repo.Migrations.AllowNullUserForComment do
  use Ecto.Migration

  def change do
    drop constraint("comments", "comments_user_id_fkey")

    alter table(:comments) do
      modify :user_id, references(:users, on_delete: :nilify_all), null: true
    end
  end
end
