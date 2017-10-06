defmodule CaptainFact.Accounts.ReputationUpdaterTest do
  use CaptainFact.DataCase
#  import ExUnit.CaptureLog

  alias CaptainFact.Accounts.{User, ReputationUpdater}
  alias CaptainFact.Actions.UserAction


  test "target user gains reputation" do
    action = insert_action(:vote_up, :comment)
    user_before = Repo.get!(User, action.target_user_id)
    {_, expected_diff} = ReputationUpdater.action_reputation_change(action.type, action.entity)

    ReputationUpdater.force_update()
    assert Repo.get!(User, action.target_user_id).reputation == user_before.reputation + expected_diff
  end

# TODO
#  test "user gains should be limited" do
#    source_user = insert(:user, %{reputation: 42000})
#    target_user = insert(:user, %{reputation: 0})
#    assert ReputationUpdater.get_today_reputation_gain(target_user) == 0
#    action = :comment_vote_up
#    limit = ReputationUpdater.max_daily_reputation_gain()
#
#    for _ <- 0..(limit * 2),
#      do: ReputationUpdater.register_action(source_user, target_user, action)
#    ReputationUpdater.wait_queue()
#
#    assert ReputationUpdater.get_today_reputation_gain(target_user) == limit
#  end

  test "some actions should have impact on both users reputation" do
    # Register action
    action = insert_action(:vote_down, :fact)
    {diff_source, diff_target} = ReputationUpdater.action_reputation_change(action.type, action.entity)
    source_user = Repo.get!(User, action.user_id)
    target_user = Repo.get!(User, action.target_user_id)
    ReputationUpdater.force_update()

    assert Repo.get!(User, action.user_id).reputation == source_user.reputation + diff_source
    assert Repo.get!(User, action.target_user_id).reputation == target_user.reputation + diff_target
  end

#  test "if an update fails, other pending updates will not crash" do
#    action = :email_confirmed
#    reputation_gain = ReputationUpdater.action_target_reputation_change(action)
#
#    some_ok_users = insert_list(10, :user)
#    invalid_user = %User{id: 454545454826666799}
#    other_ok_users = insert_list(10, :user)
#
#    all_users = some_ok_users ++ [invalid_user] ++ other_ok_users
#    assert capture_log(fn ->
#      for user <- all_users,
#        do: :ok = ReputationUpdater.register_action(user, action)
#      ReputationUpdater.wait_queue()
#    end) =~ "[warn] DB reputation update"
#
#    for user <- (some_ok_users ++ other_ok_users) do
#      assert ReputationUpdater.get_today_reputation_gain(user) == reputation_gain
#      assert Repo.get!(User, user.id).reputation == user.reputation + reputation_gain
#    end
#  end

  defp insert_action(type, entity) do
    insert(:user_action, %{type: UserAction.type(type), entity: UserAction.entity(entity)})
  end
end
