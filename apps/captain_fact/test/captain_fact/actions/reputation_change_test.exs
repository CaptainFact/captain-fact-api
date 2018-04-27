defmodule CaptainFact.Actions.ReputationChangeTest do
  use CaptainFact.DataCase

  import CaptainFact.Actions.ReputationChange
  alias DB.Schema.UserAction

  test "returns correct values for actions" do
    assert test_action(:vote_down, :comment) == {-1, -2}
    assert test_action(:vote_up, :comment) == {0, 2}
    assert test_action(:action_banned_spam) == {0, -30}
  end

  defp test_action(type) do
    for_action(%UserAction{type: UserAction.type(type)})
  end

  defp test_action(type, entity) do
    for_action(%UserAction{
      type: UserAction.type(type),
      entity: UserAction.entity(entity)
    })
  end
end