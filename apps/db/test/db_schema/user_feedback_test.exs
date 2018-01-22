defmodule DB.Schema.UserFeedbackTest do
  use DB.DataCase, async: true
  alias DB.Schema.UserFeedback

  @valid_attrs %{value: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    assert UserFeedback.changeset(%UserFeedback{user_id: 1, action_id: 1}, @valid_attrs).valid?
  end

  test "changeset with invalid attributes" do
    refute UserFeedback.changeset(%UserFeedback{user_id: 1, action_id: 1}, @invalid_attrs).valid?
  end

  test "feedback value can only be +1, 0 or -1" do
    assert {:value, "must be greater than or equal to -1"} in errors_on(%UserFeedback{}, %{value: -2})
    assert {:value, "must be less than or equal to 1"} in errors_on(%UserFeedback{}, %{value: 10})
    assert {:value, "is invalid"} in errors_on(%UserFeedback{}, %{value: "Hello"})
  end
end
