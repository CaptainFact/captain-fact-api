defmodule DB.Schema.UserActionTest do
  use DB.DataCase, async: true

  alias DB.Schema.UserAction

  @valid_attrs %{
    user_id: 1,
    context: "VD:1",
    entity: UserAction.entity(:statement),
    entity_id: 42,
    type: UserAction.type(:update),
    changes: %{
      text: "Updated !"
    }
  }
  @invalid_attrs %{}
  @must_have_changes ~w(create add update)
  @must_not_have_changes ~w(remove delete restore)
  @valid_action_types @must_have_changes ++ @must_not_have_changes

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

  test "some action types cannot have changes" do
    for action_type <- @must_not_have_changes do
      attrs =
        Map.merge(@valid_attrs, %{
          type: action_type,
          changes: %{text: "Beer Time ! 🍺🍺🍺"}
        })

      changeset = UserAction.changeset(%UserAction{}, attrs)
      refute changeset.valid?
    end
  end

  test "some action types must have changes" do
    for action_type <- @must_have_changes do
      attrs =
        Map.merge(@valid_attrs, %{
          type: action_type,
          changes: nil
        })

      changeset = UserAction.changeset(%UserAction{}, attrs)
      refute changeset.valid?
    end
  end

  test "empty changes must never be valids" do
    for action_type <- @valid_action_types do
      attrs =
        Map.merge(@valid_attrs, %{
          type: action_type,
          changes: %{}
        })

      changeset = UserAction.changeset(%UserAction{}, attrs)
      refute changeset.valid?
    end
  end
end
