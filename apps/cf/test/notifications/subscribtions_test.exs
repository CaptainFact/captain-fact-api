defmodule CF.Notifications.SubscriptionsTest do
  use CF.DataCase

  alias CF.Notifications.Subscriptions

  describe "subscribe" do
    test "should insert subscription in DB" do
      user = insert(:user)
      comment = insert(:comment)
      {:ok, subscription} = Subscriptions.subscribe(user, comment)
      assert subscription.user_id == user.id
      assert subscription.comment_id == comment.id
      assert subscription.is_subscribed == true
    end

    test "must insert only one subscription" do
      user = insert(:user)
      comment = insert(:comment)
      {:ok, subscription1} = Subscriptions.subscribe(user, comment)
      {:ok, subscription2} = Subscriptions.subscribe(user, comment)
      assert subscription1.id == subscription2.id
    end

    test "works on statements, comments and videos" do
      user = insert(:user)
      video = insert(:video)
      statement = insert(:statement, video: video)
      comment = insert(:comment, statement: statement)

      # Subscribe to all entities except video
      {:ok, _} = Subscriptions.subscribe(user, statement)
      {:ok, _} = Subscriptions.subscribe(user, comment)
      {:ok, _} = Subscriptions.subscribe(user, video)
    end
  end
end
