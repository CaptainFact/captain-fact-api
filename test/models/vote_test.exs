defmodule CaptainFact.VoteTest do
  use CaptainFact.ModelCase

  alias CaptainFact.Vote

  @valid_attrs %{is_positive: true}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Vote.changeset(%Vote{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Vote.changeset(%Vote{}, @invalid_attrs)
    refute changeset.valid?
  end
end
