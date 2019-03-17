defmodule DB.Schema.SubscriptionTest do
  use DB.DataCase, async: true
  doctest DB.Schema.Subscription

  import DB.Factory
  alias DB.Schema.Subscription

  @valid_attrs %{
    user_id: 1,
    video_id: 1,
    statement_id: 1,
    comment_id: 1,
    scope: :comment,
    is_subscribed: true
  }

  test "valid params" do
    changeset = Subscription.changeset(%Subscription{}, @valid_attrs)
    assert changeset.valid?
  end

  test "scope must be valid" do
    params = %{@valid_attrs | scope: :bad_valueeeee}
    changeset = Subscription.changeset(%Subscription{}, params)
    refute changeset.valid?
    assert {"is invalid", _} = changeset.errors[:scope]
  end

  describe "some params are mandatory depending on scope" do
    test "for videos" do
      params = %{@valid_attrs | video_id: nil}
      changeset = Subscription.changeset(%Subscription{}, params)
      refute changeset.valid?
    end

    test "for statements" do
      params = %{@valid_attrs | video_id: nil}
      changeset = Subscription.changeset(%Subscription{}, params)
      refute changeset.valid?

      params = %{@valid_attrs | statement_id: nil}
      changeset = Subscription.changeset(%Subscription{}, params)
      refute changeset.valid?
    end

    test "for comments" do
      params = %{@valid_attrs | video_id: nil}
      changeset = Subscription.changeset(%Subscription{}, params)
      refute changeset.valid?

      params = %{@valid_attrs | statement_id: nil}
      changeset = Subscription.changeset(%Subscription{}, params)
      refute changeset.valid?

      params = %{@valid_attrs | comment_id: nil}
      changeset = Subscription.changeset(%Subscription{}, params)
      refute changeset.valid?
    end
  end

  describe "changeset_entity builds specific changeset" do
    test "for video" do
      user_subscription = %Subscription{user_id: 1}
      video = insert(:video)
      changeset = Subscription.changeset_entity(user_subscription, video)
      assert changeset.changes.scope == :video
      assert changeset.changes.video_id == video.id
    end

    test "for statement" do
      user_subscription = %Subscription{user_id: 1}
      statement = insert(:statement)
      changeset = Subscription.changeset_entity(user_subscription, statement)
      assert changeset.changes.scope == :statement
      assert changeset.changes.video_id == statement.video_id
      assert changeset.changes.statement_id == statement.id
    end

    test "for comment" do
      user_subscription = %Subscription{user_id: 1}
      comment = insert(:comment)
      changeset = Subscription.changeset_entity(user_subscription, comment)
      assert changeset.changes.scope == :comment
      assert changeset.changes.video_id == comment.statement.video_id
      assert changeset.changes.statement_id == comment.statement.id
      assert changeset.changes.comment_id == comment.id
    end
  end
end
