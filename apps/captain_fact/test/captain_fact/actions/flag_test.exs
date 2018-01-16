defmodule CaptainFact.Actions.FlagTest do
  use CaptainFact.DataCase, async: true

  alias CaptainFact.Actions.Flag


  test "changeset with valid attributes" do
    changeset = Flag.changeset(%Flag{source_user_id: 42}, %{reason: 1, action_id: 42})
    assert changeset.valid?
  end

  test "reason cannot be anything" do
    changeset = Flag.changeset(%Flag{source_user_id: 42}, %{reason: 0, action_id: 42})
    refute changeset.valid?

    changeset = Flag.changeset(%Flag{source_user_id: 42}, %{reason: 4500, action_id: 42})
    refute changeset.valid?
  end
end
