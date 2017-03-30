defmodule CaptainFact.VideoAdminTest do
  use CaptainFact.ModelCase

  alias CaptainFact.VideoAdmin

  @valid_attrs %{}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = VideoAdmin.changeset(%VideoAdmin{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = VideoAdmin.changeset(%VideoAdmin{}, @invalid_attrs)
    refute changeset.valid?
  end
end
