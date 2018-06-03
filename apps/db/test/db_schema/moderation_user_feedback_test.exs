defmodule DB.Schema.ModerationUserFeedbackTest do
  use DB.DataCase, async: true
  alias DB.Schema.ModerationUserFeedback
  import DB.Schema.ModerationUserFeedback, only: [changeset: 2]

  @valid_attrs %{value: 1, flag_reason: 1}
  @base_feedback %ModerationUserFeedback{user_id: 1, action_id: 1}

  test "changeset with valid attributes" do
    assert changeset(@base_feedback, @valid_attrs).valid?
  end

  test "feedback value can only be +1, 0 or -1" do
    assert {:value, "must be greater than or equal to -1"} in errors_on(@base_feedback, %{
             value: -2
           })

    assert {:value, "must be less than or equal to 1"} in errors_on(@base_feedback, %{value: 10})
    assert {:value, "is invalid"} in errors_on(@base_feedback, %{value: "Hello"})
  end

  test "reason cannot be anything" do
    refute changeset(@base_feedback, %{@valid_attrs | flag_reason: 5000}).valid?
    refute changeset(@base_feedback, %{@valid_attrs | flag_reason: 0}).valid?
  end
end
