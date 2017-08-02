defmodule CaptainFact.Accounts.ReputationUpdaterTest do
  use CaptainFact.DataCase

  import ExUnit.CaptureLog
  alias CaptainFact.Accounts.{User, UserState, ReputationUpdater}

  setup do
    UserState.reset()
    source_user = insert(:user, %{reputation: 42000})
    target_user = insert(:user, %{reputation: 0})
    {:ok, [source_user: source_user, target_user: target_user]}
  end

  test "target user gains reputation", context do
    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == 0
    {action, {_, points_target}} = Enum.random(ReputationUpdater.actions)
    ReputationUpdater.register_action(context[:source_user], context[:target_user], action)
    ReputationUpdater.wait_queue()

    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == points_target
  end

  test "user gains should be limited", context do
    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == 0
    action = :comment_vote_up
    limit = ReputationUpdater.max_daily_reputation_gain()

    for _ <- 0..(limit * 2),
      do: ReputationUpdater.register_action(context[:source_user], context[:target_user], action)
    ReputationUpdater.wait_queue()

    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == limit
  end

  test "user reputation is saved in database", context do
    prev_reputation = Repo.get(User, context[:target_user].id).reputation
    {action, {_, points_target}} = Enum.random(ReputationUpdater.actions)
    ReputationUpdater.register_action(context[:source_user], context[:target_user], action)
    ReputationUpdater.wait_queue()

    assert Repo.get(User, context[:target_user].id).reputation == prev_reputation + points_target
  end

  test "some actions should have impact on both users reputation", context do
    source_user = Repo.get!(User, context[:source_user].id)
    target_user = Repo.get!(User, context[:target_user].id)

    # Check that state is clean
    assert ReputationUpdater.get_today_reputation_gain(source_user) == 0
    assert ReputationUpdater.get_today_reputation_gain(target_user) == 0

    # Register action
    action = :comment_vote_down
    {points_source, points_target} = Map.get(ReputationUpdater.actions, :comment_vote_down)
    ReputationUpdater.register_action(source_user, target_user, action)
    ReputationUpdater.wait_queue()

    # In UserState
    assert ReputationUpdater.get_today_reputation_gain(source_user) == points_source
    assert ReputationUpdater.get_today_reputation_gain(target_user) == points_target

    # In DB
    assert Repo.get!(User, source_user.id).reputation == source_user.reputation + points_source
    assert Repo.get!(User, target_user.id).reputation == target_user.reputation + points_target
  end

  test "if an update fails, other pending updates will not crash" do
    action = :email_confirmed
    reputation_gain = ReputationUpdater.action_target_reputation_change(action)

    some_ok_users = insert_list(10, :user)
    invalid_user = %User{id: 454545454826666799}
    other_ok_users = insert_list(10, :user)

    all_users = some_ok_users ++ [invalid_user] ++ other_ok_users
    assert capture_log(fn ->
      for user <- all_users,
        do: :ok = ReputationUpdater.register_action(user, action)
      ReputationUpdater.wait_queue()
    end) =~ "[warn] DB reputation update"

    for user <- (some_ok_users ++ other_ok_users) do
      assert ReputationUpdater.get_today_reputation_gain(user) == reputation_gain
      assert Repo.get!(User, user.id).reputation == user.reputation + reputation_gain
    end
  end
end
