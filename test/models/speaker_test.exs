defmodule CaptainFact.SpeakerTest do
  use CaptainFact.ModelCase

  alias CaptainFact.Speaker

  @valid_attrs %{full_name: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Speaker.changeset(%Speaker{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Speaker.changeset(%Speaker{}, @invalid_attrs)
    refute changeset.valid?
  end
end
