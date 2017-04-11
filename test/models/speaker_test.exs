defmodule CaptainFact.SpeakerTest do
  use CaptainFact.ModelCase, async: true

  alias CaptainFact.Speaker

  @valid_attrs %{
    full_name: "#{Faker.Name.first_name} #{Faker.Name.last_name}"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Speaker.changeset(%Speaker{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Speaker.changeset(%Speaker{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "full name must be between 3 and 60 characters" do
    # Too short
    attrs = %{full_name: "x"}
    assert {:full_name, "should be at least 3 character(s)"} in errors_on(%Speaker{}, attrs)

    # Too long
    attrs = %{full_name: String.duplicate("x", 61)}
    assert {:full_name, "should be at most 60 character(s)"} in errors_on(%Speaker{}, attrs)
  end

  test "title must be between 3 and 60 characters" do
    # Too short
    attrs = %{title: "x"}
    assert {:title, "should be at least 3 character(s)"} in errors_on(%Speaker{}, attrs)

    # Too long
    attrs = %{title: String.duplicate("x", 61)}
    assert {:title, "should be at most 60 character(s)"} in errors_on(%Speaker{}, attrs)
  end
end
