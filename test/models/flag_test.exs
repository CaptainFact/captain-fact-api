defmodule CaptainFact.FlagTest do
  use CaptainFact.ModelCase

  alias CaptainFact.Flag

  @valid_attrs %{entity_id: 42, type: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Flag.changeset(%Flag{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Flag.changeset(%Flag{}, @invalid_attrs)
    refute changeset.valid?
  end
end
