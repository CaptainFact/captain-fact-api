defmodule DB.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def up do
    DB.Type.NotificationType.create_type()

    create table(:notifications) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      add(:action_id, references(:users_actions, on_delete: :delete_all), null: false)
      add(:type, :notification_type, null: false)
      add(:seen_at, :utc_datetime, null: true, default: nil)

      timestamps()
    end

    create(index(:notifications, [:user_id, :action_id]))
  end

  def down do
    drop(index(:notifications, [:user_id, :action_id]))
    drop(table(:notifications))
    DB.Type.NotificationType.drop_type()
  end
end
