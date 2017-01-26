defmodule CaptainFact.VideoTest do
  use CaptainFact.ModelCase

  alias CaptainFact.Video

  @valid_attrs %{is_private: true, url: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Video.changeset(%Video{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Video.changeset(%Video{}, @invalid_attrs)
    refute changeset.valid?
  end
end
