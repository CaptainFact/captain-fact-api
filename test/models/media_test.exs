defmodule CaptainFact.MediaTest do
  use CaptainFact.ModelCase

  alias CaptainFact.Media

  @valid_attrs %{name: "some content", url_pattern: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Media.changeset(%Media{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Media.changeset(%Media{}, @invalid_attrs)
    refute changeset.valid?
  end
end
