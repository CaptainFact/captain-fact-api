defmodule CF.Jobs.CreateNotificationsTest do
  use CF.Jobs.DataCase
  alias DB.Schema.UserAction
  alias DB.Schema.Notification
  alias CF.Jobs.CreateNotifications

  test "creates notifications" do
    DB.Repo.delete_all(Notification)
    DB.Repo.delete_all(UserAction)

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

    CreateNotifications.handle_call(:update, nil, nil)

    [notification] = DB.Repo.all(Notification)
    assert notification.user_id == subscription.user_id
    assert notification.action_id == action.id
    assert notification.seen_at == nil
    assert notification.type == :new_statement
  end
end
