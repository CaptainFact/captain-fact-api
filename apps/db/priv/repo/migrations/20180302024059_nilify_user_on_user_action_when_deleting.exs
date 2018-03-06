defmodule DB.Repo.Migrations.NilifyUserOnUserActionWhenDeleting do
  use Ecto.Migration

  def change do
    drop constraint("users_actions", "users_actions_user_id_fkey")
    drop constraint("users_actions", "users_actions_target_user_id_fkey")

    alter table(:users_actions) do
      modify :user_id, references(:users, on_delete: :nilify_all)
      modify :target_user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
