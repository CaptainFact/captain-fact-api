defmodule DB.Schema.UserActionTest do
  use DB.DataCase, async: true

  alias DB.Schema.UserAction

  @valid_attrs %{
    user_id: 1,
    entity: UserAction.entity(:statement),
    comment_id: 42,
    type: :update,
    changes: %{
      text: "Updated !"
    }
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = UserAction.changeset(%UserAction{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = UserAction.changeset(%UserAction{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "entity cannot be anything" do
    attrs = Map.put(@valid_attrs, :entity, "Not a valid entity !")
    changeset = UserAction.changeset(%UserAction{}, attrs)
    refute changeset.valid?
  end

  test "action type must be create, remove, update, delete, or add" do
    attrs = Map.put(@valid_attrs, :type, "invalid_action_type")
    changeset = UserAction.changeset(%UserAction{}, attrs)
    refute changeset.valid?
  end
end
