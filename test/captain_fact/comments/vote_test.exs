defmodule CaptainFact.Comments.VoteTest do
  use CaptainFact.DataCase, async: true
  doctest CaptainFact.Comments.Vote

  alias CaptainFact.Comments.Vote

  @valid_attrs %{user_id: 1, comment_id: 1, value: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Vote.changeset(%Vote{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Vote.changeset(%Vote{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "vote value can only be +1 or -1" do
    assert {:value, "is invalid"} in errors_on(%Vote{}, %{value: -2})
    assert {:value, "is invalid"} in errors_on(%Vote{}, %{value: 10})
    assert {:value, "is invalid"} in errors_on(%Vote{}, %{value: "Hello"})
  end
end
