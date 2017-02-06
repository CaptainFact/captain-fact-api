defmodule CaptainFact.StatementTest do
  use CaptainFact.ModelCase

  alias CaptainFact.Statement

  @valid_attrs %{status: 42, text: "some content", truthiness: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Statement.changeset(%Statement{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Statement.changeset(%Statement{}, @invalid_attrs)
    refute changeset.valid?
  end
end
