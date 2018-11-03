defmodule CF.Notifications.SubscriptionsMatcherTest do
  use CF.DataCase

  alias CF.Actions.ActionCreator
  alias CF.Notifications.SubscriptionsMatcher

  describe "match_action/1 returns correct subscriptions" do
    setup do
      video = insert(:video)
      statement = insert(:statement, video: video)
      comment = insert(:comment, statement: statement)

      [
        entities: [
          video: video,
          statement: statement,
          comment: comment
        ],
        subscriptions: [
          video:
            insert(
              :subscription,
              video: video,
              scope: :video
            ),
          statement:
            insert(
              :subscription,
              video: video,
              statement: statement,
              scope: :statement
            ),
          comment:
            insert(
              :subscription,
              video: video,
              statement: statement,
              comment: comment,
              reason: :is_author,
              scope: :comment
            ),
          random: insert(:subscription)
        ]
      ]
    end

    test "for new comment reply", %{entities: entities, subscriptions: subscriptions} do
      reply = insert(:comment, reply_to: entities[:comment])

      # They should all be notified for new comment reply
      action =
        Repo.insert!(
          ActionCreator.action_create(
            insert(:user).id,
            entities[:video].id,
            reply
          )
        )

      expected_subscriptions = Keyword.take(subscriptions, [:video, :statement, :comment])
      returned_subscriptions = SubscriptionsMatcher.match_action(action)
      compare_subscriptions_ids(expected_subscriptions, returned_subscriptions)
    end

    test "for new statement", %{entities: entities, subscriptions: subscriptions} do
      user = insert(:user)
      statement = insert(:statement, video: entities[:video])
      action = Repo.insert!(ActionCreator.action_create(user.id, statement))
      expected_subscriptions = Keyword.take(subscriptions, [:video, :statement])

      returned_subscriptions = SubscriptionsMatcher.match_action(action)
      compare_subscriptions_ids(expected_subscriptions, returned_subscriptions)
    end

    test "for updated statement", %{entities: entities, subscriptions: subscriptions} do
      user = insert(:user)
      statement = insert(:statement, video: entities[:video])
      changeset = Ecto.Changeset.change(statement, text: "Changed")
      action = Repo.insert!(ActionCreator.action_update(user.id, changeset))
      expected_subscriptions = Keyword.take(subscriptions, [:video, :statement])

      returned_subscriptions = SubscriptionsMatcher.match_action(action)
      compare_subscriptions_ids(expected_subscriptions, returned_subscriptions)
    end

    test "for removed statement", %{entities: entities, subscriptions: subscriptions} do
      user = insert(:user)
      statement = insert(:statement, video: entities[:video])
      action = Repo.insert!(ActionCreator.action_remove(user.id, statement))
      expected_subscriptions = Keyword.take(subscriptions, [:video, :statement])

      returned_subscriptions = SubscriptionsMatcher.match_action(action)
      compare_subscriptions_ids(expected_subscriptions, returned_subscriptions)
    end

    test "for video updated", %{entities: entities, subscriptions: subscriptions} do
      action =
        Repo.insert!(
          ActionCreator.action(
            insert(:user).id,
            :video,
            :update,
            video_id: entities[:video].id,
            changes: %{"statements_time" => 42}
          )
        )

      expected_subscriptions = Keyword.take(subscriptions, [:video])
      returned_subscriptions = SubscriptionsMatcher.match_action(action)
      compare_subscriptions_ids(expected_subscriptions, returned_subscriptions)
    end

    test "for speaker added", %{entities: entities, subscriptions: subscriptions} do
      user = insert(:user)
      speaker = insert(:speaker)
      action = Repo.insert!(ActionCreator.action_add(user.id, entities[:video].id, speaker))
      expected_subscriptions = Keyword.take(subscriptions, [:video])
      returned_subscriptions = SubscriptionsMatcher.match_action(action)
      compare_subscriptions_ids(expected_subscriptions, returned_subscriptions)
    end

    test "for speaker removed", %{entities: entities, subscriptions: subscriptions} do
      user = insert(:user)
      speaker = insert(:speaker)
      action = Repo.insert!(ActionCreator.action_remove(user.id, entities[:video].id, speaker))
      expected_subscriptions = Keyword.take(subscriptions, [:video])
      returned_subscriptions = SubscriptionsMatcher.match_action(action)
      compare_subscriptions_ids(expected_subscriptions, returned_subscriptions)
    end
  end

  defp compare_subscriptions_ids(expected_subscriptions, returned_subscriptions) do
    # Sort both lists to be able to compare them. Another solution would have
    # been to generate a diff, but this is prettier in test logs.
    expected_subscriptions_ids =
      expected_subscriptions |> Enum.map(fn {_, v} -> v.id end) |> Enum.sort()

    returned_subscriptions_ids =
      returned_subscriptions |> Enum.map(fn v -> v.id end) |> Enum.sort()

    assert expected_subscriptions_ids == returned_subscriptions_ids
  end
end
