defmodule CaptainFact.ReputationUpdaterTest do
  use ExUnit.Case, async: false
  alias CaptainFact.{ReputationUpdater, User, UserState, Repo}

  setup do
    UserState.reset()
  end

  setup_all do
    user = %User{id: 1, reputation: 0}
    {:ok, [user: user]}
  end

  test "user gains reputation", context do
    assert ReputationUpdater.get_today_reputation_gain(context[:user]) == 0
    {action, points} = Enum.random(ReputationUpdater.actions)
    ReputationUpdater.register_change(context[:user], action)
    assert ReputationUpdater.get_today_reputation_gain(context[:user]) == points
  end

  test "user gains should be limited", context do
    assert ReputationUpdater.get_today_reputation_gain(context[:user]) == 0
    action = :comment_vote_up
    limit = ReputationUpdater.max_daily_reputation_gain()

    for _ <- 0..(limit * 2),
    do: ReputationUpdater.register_change(context[:user], action)
    assert ReputationUpdater.get_today_reputation_gain(context[:user]) == limit
  end

  test "user reputation in saved in database", context do
    reputation_before = Repo.get!(User, 1).reputation
    {action, points} = Enum.random(ReputationUpdater.actions)
    ReputationUpdater.register_change(context[:user], action)
    assert Repo.get(User, 1).reputation == reputation_before + points
  end
end
