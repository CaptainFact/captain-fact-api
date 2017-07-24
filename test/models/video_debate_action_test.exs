defmodule CaptainFact.VideoDebateActionTest do
  use CaptainFact.ModelCase

  alias CaptainFact.Web.VideoDebateAction

  @valid_attrs %{
    user_id: 1,
    video_id: 2,
    entity: "statement",
    entity_id: 42,
    type: "update",
    changes: %{
      text: "Updated !"
    }
  }
  @invalid_attrs %{}
  @must_have_changes ~w(create add update)
  @must_not_have_changes ~w(remove delete restore)
  @valid_action_types @must_have_changes ++ @must_not_have_changes



  test "changeset with valid attributes" do
    changeset = VideoDebateAction.changeset(%VideoDebateAction{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = VideoDebateAction.changeset(%VideoDebateAction{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "entity cannot be anything" do
    attrs = Map.put(@valid_attrs, :entity, "Not a valid entity !")
    changeset = VideoDebateAction.changeset(%VideoDebateAction{}, attrs)
    refute changeset.valid?
  end

  test "action type must be create, remove, update, delete, or add" do
    attrs = Map.put(@valid_attrs, :type, "invalid_action_type")
    changeset = VideoDebateAction.changeset(%VideoDebateAction{}, attrs)
    refute changeset.valid?
  end

  test "some action types cannot have changes" do
    for action_type <- @must_not_have_changes do
      attrs = Map.merge @valid_attrs, %{
        type: action_type,
        changes: %{text: "Beer Time ! 🍺🍺🍺"}
      }
      changeset = VideoDebateAction.changeset(%VideoDebateAction{}, attrs)
      refute changeset.valid?
    end
  end

  test "some action types must have changes" do
    for action_type <- @must_have_changes do
      attrs = Map.merge @valid_attrs, %{
        type: action_type,
        changes: nil
      }
      changeset = VideoDebateAction.changeset(%VideoDebateAction{}, attrs)
      refute changeset.valid?
    end
  end

  test "empty changes must never be valids" do
    for action_type <- @valid_action_types do
      attrs = Map.merge @valid_attrs, %{
        type: action_type,
        changes: %{}
      }
      changeset = VideoDebateAction.changeset(%VideoDebateAction{}, attrs)
      refute changeset.valid?
    end
  end
end
