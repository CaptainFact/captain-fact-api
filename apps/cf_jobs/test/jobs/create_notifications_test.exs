defmodule CF.Jobs.CreateNotificationsTest do
  use CF.Jobs.DataCase, async: false
  alias DB.Schema.UserAction
  alias DB.Schema.Notification
  alias DB.Schema.UsersActionsReport
  alias CF.Jobs.CreateNotifications

  test "creates notifications" do
    DB.Repo.delete_all(Notification)
    DB.Repo.delete_all(UserAction)
    DB.Repo.delete_all(UsersActionsReport)

    subscription = insert(:subscription)
    statement = insert(:statement, video: subscription.video)

    action =
      insert(
        :user_action,
        type: :create,
        entity: :statement,
        video: subscription.video,
        statement: statement
      )

    CreateNotifications.update(true)

    [notification] = DB.Repo.all(Notification)
    assert notification.user_id == subscription.user_id
    assert notification.action_id == action.id
    assert notification.seen_at == nil
    assert notification.type == :new_statement
  end
end
