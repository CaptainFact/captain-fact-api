defmodule DB.Schema.FlagTest do
  use DB.DataCase, async: true

  alias DB.Schema.Flag


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
