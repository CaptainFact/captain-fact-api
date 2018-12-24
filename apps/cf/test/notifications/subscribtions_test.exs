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

  describe "unsubscribe" do
    test "removes existing subscription on video" do
      video = insert(:video)
      subscription = insert(:subscription, scope: :video, video: video)
      Subscriptions.unsubscribe(subscription.user, subscription.video)
      refute Repo.get(DB.Schema.Subscription, subscription.id)
    end

    test "removes existing subscription on statement" do
      statement = insert(:statement)

      subscription =
        insert(:subscription, scope: :statement, video: statement.video, statement: statement)

      Subscriptions.unsubscribe(subscription.user, subscription.statement)
      refute Repo.get(DB.Schema.Subscription, subscription.id)
    end

    test "removes existing subscription on comment" do
      comment = insert(:comment)

      subscription =
        insert(:subscription,
          scope: :comment,
          video: comment.statement.video,
          statement: comment.statement,
          comment: comment
        )

      Subscriptions.unsubscribe(subscription.user, subscription.comment)
      refute Repo.get(DB.Schema.Subscription, subscription.id)
    end
  end

  describe "subscribe, unsubscribe and is_subscribed togethers" do
    test "simple" do
      user = insert(:user)
      video = insert(:video)
      refute Subscriptions.is_subscribed(user, video)
      {:ok, _} = Subscriptions.subscribe(user, video)
      assert Subscriptions.is_subscribed(user, video)
      {:ok, _} = Subscriptions.unsubscribe(user, video)
      refute Subscriptions.is_subscribed(user, video)
    end
  end
end
