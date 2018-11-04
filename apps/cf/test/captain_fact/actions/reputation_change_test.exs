defmodule CF.Actions.ReputationChangeTest do
  use CF.DataCase

  import CF.Actions.ReputationChange
  alias DB.Schema.UserAction

  test "returns correct values for actions" do
    assert test_action(:vote_down, :comment) == {-1, -2}
    assert test_action(:vote_up, :comment) == {0, 2}
    assert test_action(:action_banned_spam) == {0, -30}
  end

  describe "estimate_reputation_change" do
    test "recognize self actions" do
      # Create user and a single action with previsible results
      user = insert(:user)
      action_type = :vote_down
      entity = :comment
      action = insert(:user_action, user: user, type: action_type, entity: entity)

      # Estimate change and ensure it matches the change for this action
      {expected_source_change, _} = for_action(action_type, entity)
      result = estimate_reputation_change([action], user)
      assert result == expected_source_change
    end

    test "recognize target actions" do
      # Create user and a single action with previsible results
      user = insert(:user)
      action_type = :email_confirmed
      entity = :user
      action = insert(:user_action, target_user: user, type: action_type, entity: entity)

      # Estimate change and ensure it matches the change for this action
      {_, expected_target_change} = for_action(action_type)
      result = estimate_reputation_change([action], user)
      assert result == expected_target_change
    end

    test "correctly sum up the total" do
      # Create user with 2 actions with previsible results
      user = insert(:user)

      # Self action
      self_entity = :comment
      self_action_type = :vote_down
      self_action = insert(:user_action, user: user, type: self_action_type, entity: self_entity)

      # Target action
      target_entity = :user
      target_action_type = :email_confirmed

      target_action =
        insert(:user_action, target_user: user, type: target_action_type, entity: target_entity)

      # Calculate expected total
      {expected_source_change, _} = for_action(self_action_type, self_entity)
      {_, expected_target_change} = for_action(target_action_type)
      expected_total = expected_source_change + expected_target_change

      # Calculate it with `estimate_reputation_change/1` and compare results
      result = estimate_reputation_change([self_action, target_action], user)
      assert result == expected_total
    end

    test "ignores actions that doesn't concern user" do
      # Create user and a single action with previsible results
      user = insert(:user)
      action_type = :email_confirmed
      entity = :user
      action = insert(:user_action, target_user: user, type: action_type, entity: entity)

      # Insert a random action that should not have any impact on calculation
      random_action = insert(:user_action, type: action_type, entity: entity)

      # Estimate change and ensure it matches the change for this action
      {_, expected_target_change} = for_action(action_type)
      result = estimate_reputation_change([action, random_action], user)
      assert result == expected_target_change
    end
  end

  defp test_action(type) do
    for_action(%UserAction{type: type})
  end

  defp test_action(type, entity) do
    for_action(%UserAction{
      type: type,
      entity: entity
    })
  end
end
