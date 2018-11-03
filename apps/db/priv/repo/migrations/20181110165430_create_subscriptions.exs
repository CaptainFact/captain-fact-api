defmodule DB.Repo.Migrations.Createsubscriptions do
  use Ecto.Migration

  def up do
    DB.Type.SubscriptionReason.create_type()

    create table(:subscriptions) do
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      add(:video_id, references(:videos, on_delete: :delete_all), null: false)
      add(:statement_id, references(:statements, on_delete: :delete_all))
      add(:comment_id, references(:comments, on_delete: :delete_all))
      add(:scope, :integer, null: false)

      add(:reason, :subscription_reason)
      add(:is_subscribed, :boolean, default: true, null: false)
    end

    create(unique_index(:subscriptions, [:user_id, :video_id, :statement_id, :comment_id]))
  end

  def down do
    DB.Type.SubscriptionReason.drop_type()
    drop(table(:subscriptions))
  end
end
