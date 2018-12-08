defmodule CF.NotificationsTest do
  use CF.DataCase

  alias CF.Notifications

  describe "all" do
    setup do
      user = insert(:user)
      notifs = insert_list(5, :notification, user: user)

      sorted_notifs_ids =
        notifs |> Enum.sort_by(& &1.inserted_at, &>=/2) |> Enum.map(&Map.get(&1, :id))

      [user: user, notifs: notifs, sorted_notifs_ids: sorted_notifs_ids]
    end

    test "sorts notifications", %{user: user, sorted_notifs_ids: sorted_notifs_ids} do
      returned_ids = Enum.map(Notifications.all(user, 1, 5), & &1.id)
      assert returned_ids == sorted_notifs_ids
    end
  end

  describe "create!" do
  end

  describe "mark_as_seen/1" do
    test "mark the notification as seen" do
      notification = insert(:notification, seen_at: nil)
      {:ok, updated} = Notifications.mark_as_seen(notification)
      refute is_nil(updated.seen_at)
    end
  end
end
