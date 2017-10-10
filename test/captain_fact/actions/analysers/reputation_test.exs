defmodule CaptainFact.Actions.Analysers.ReputationTest do
  use CaptainFact.DataCase
#  import ExUnit.CaptureLog

  alias CaptainFact.Accounts.User
  alias CaptainFact.Actions.UserAction
  alias CaptainFact.Actions.Analysers.Reputation


  test "target user gains reputation" do
    action = insert_action(:vote_up, :comment)
    user_before = Repo.get!(User, action.target_user_id)
    {_, expected_diff} = Reputation.action_reputation_change(action.type, action.entity)

    Reputation.update()
    assert Repo.get!(User, action.target_user_id).reputation == user_before.reputation + expected_diff
  end

# TODO
#  test "user gains should be limited" do
#    source_user = insert(:user, %{reputation: 42000})
#    target_user = insert(:user, %{reputation: 0})
#    assert Reputation.get_today_reputation_gain(target_user) == 0
#    action = :comment_vote_up
#    limit = Reputation.max_daily_reputation_gain()
#
#    for _ <- 0..(limit * 2),
#      do: Reputation.register_action(source_user, target_user, action)
#    Reputation.wait_queue()
#
#    assert Reputation.get_today_reputation_gain(target_user) == limit
#  end

  test "some actions should have impact on both users reputation" do
    # Register action
    action = insert_action(:vote_down, :fact)
    {diff_source, diff_target} = Reputation.action_reputation_change(action.type, action.entity)
    source_user = Repo.get!(User, action.user_id)
    target_user = Repo.get!(User, action.target_user_id)
    Reputation.update()

    assert Repo.get!(User, action.user_id).reputation == source_user.reputation + diff_source
    assert Repo.get!(User, action.target_user_id).reputation == target_user.reputation + diff_target
  end

  defp insert_action(type, entity) do
    insert(:user_action, %{type: UserAction.type(type), entity: UserAction.entity(entity)})
  end
end
