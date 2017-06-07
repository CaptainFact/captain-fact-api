defmodule CaptainFact.ReputationUpdaterTest do
  use ExUnit.Case, async: false
  alias CaptainFact.{ReputationUpdater, User, UserState, Repo}

  setup do
    UserState.reset()
  end

  setup_all do
    Repo.delete_all(User)
    source_user = Repo.insert! Map.merge(gen_user(1), %{reputation: 4200})
    target_user = Repo.insert! Map.merge(gen_user(2), %{reputation: 0})
    {:ok, [source_user: source_user, target_user: target_user]}
  end

  defp gen_user(seed) do
    %User{
      name: "Jouje BigBrother",
      username: "User #{seed}",
      email: Faker.Internet.email,
      encrypted_password: "@StrongP4ssword!"
    }
  end

  test "target user gains reputation", context do
    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == 0
    {action, {_, points_target}} = Enum.random(ReputationUpdater.actions)
    ReputationUpdater.register_action(context[:source_user], context[:target_user], action, false)
    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == points_target
  end

  test "user gains should be limited", context do
    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == 0
    action = :comment_vote_up
    limit = ReputationUpdater.max_daily_reputation_gain()

    for _ <- 0..(limit * 2),
    do: ReputationUpdater.register_action(context[:source_user], context[:target_user], action, false)
    assert ReputationUpdater.get_today_reputation_gain(context[:target_user]) == limit
  end

  test "user reputation is saved in database", context do
    prev_reputation = Repo.get(User, context[:target_user].id).reputation
    {action, {_, points_target}} = Enum.random(ReputationUpdater.actions)
    ReputationUpdater.register_action(context[:source_user], context[:target_user], action, false)
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
    ReputationUpdater.register_action(source_user, target_user, action, false)

    # In UserState
    assert ReputationUpdater.get_today_reputation_gain(source_user) == points_source
    assert ReputationUpdater.get_today_reputation_gain(target_user) == points_target

    # In DB
    assert Repo.get!(User, source_user.id).reputation == source_user.reputation + points_source
    assert Repo.get!(User, target_user.id).reputation == target_user.reputation + points_target
  end
end
