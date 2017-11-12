defmodule CaptainFact.Moderation.UserFeedbackTest do
  use CaptainFact.DataCase, async: true
  alias CaptainFact.Moderation.UserFeedback

  @valid_attrs %{feedback: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    assert UserFeedback.changeset(%UserFeedback{user_id: 1, action_id: 1}, @valid_attrs).valid?
  end

  test "changeset with invalid attributes" do
    refute UserFeedback.changeset(%UserFeedback{user_id: 1, action_id: 1}, @invalid_attrs).valid?
  end

  test "feedback can only be +1, 0 or -1" do
    assert {:feedback, "must be greater than or equal to -1"} in errors_on(%UserFeedback{}, %{feedback: -2})
    assert {:feedback, "must be less than or equal to 1"} in errors_on(%UserFeedback{}, %{feedback: 10})
    assert {:feedback, "is invalid"} in errors_on(%UserFeedback{}, %{feedback: "Hello"})
  end
end
