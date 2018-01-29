defmodule CaptainFact.Jobs.ReputationTest do
  use CaptainFact.DataCase

  alias DB.Schema.User
  alias DB.Schema.UserAction
  alias CaptainFact.Jobs.Reputation


  test "target user gains reputation" do
    action = insert_action(:vote_up, :comment)
    user_before = Repo.get!(User, action.target_user_id)
    {_, expected_diff} = Reputation.action_reputation_change(action.type, action.entity)

    Reputation.update()
    updated_user = Repo.get!(User, action.target_user_id)
    assert updated_user.reputation == user_before.reputation + expected_diff
    assert updated_user.today_reputation_gain == user_before.today_reputation_gain + expected_diff
  end

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

  test "user gains should be limited, but loosing reputation should still happen" do
    source_user = insert(:user, %{reputation: 42000})
    target_user = insert(:user, %{reputation: 0})
    limit = Reputation.daily_gain_limit()
    insert_list(limit * 2, :user_action, %{
      type: UserAction.type(:vote_up),
      entity: UserAction.entity(:comment),
      user: source_user,
      target_user: target_user
    })

    # Ensure we don't exceed limit
    Reputation.update()
    updated_user = Repo.get!(User, target_user.id)
    assert updated_user.reputation == target_user.reputation + limit
    assert updated_user.today_reputation_gain == limit

    # Ensure we still loose reputation
    type = :vote_down
    entity = :comment
    {_, expected_diff} = Reputation.action_reputation_change(type, entity)
    insert(:user_action, %{
      type: UserAction.type(type),
      entity: UserAction.entity(entity),
      user: source_user,
      target_user: target_user
    })

    Reputation.update()
    final_user = Repo.get!(User, target_user.id)
    assert final_user.reputation == updated_user.reputation + expected_diff
    assert final_user.today_reputation_gain == limit + expected_diff
  end

  test "reset_daily_limits/0 reset all users limits" do
    action = insert_action(:vote_up, :comment)
    {_, expected_diff} = Reputation.action_reputation_change(action.type, action.entity)

    Reputation.update()
    updated_user = Repo.get!(User, action.target_user_id)
    assert updated_user.today_reputation_gain == expected_diff

    Reputation.reset_daily_limits()
    updated_user = Repo.get!(User, action.target_user_id)
    assert updated_user.today_reputation_gain == 0
  end

  defp insert_action(type, entity) do
    insert(:user_action, %{type: UserAction.type(type), entity: UserAction.entity(entity)})
  end
end
