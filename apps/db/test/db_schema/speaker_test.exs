defmodule DB.Schema.SpeakerTest do
  use DB.DataCase, async: true

  alias DB.Schema.Speaker

  @valid_attrs %{
    full_name: "#{Faker.Name.first_name()} #{Faker.Name.last_name()}",
    wikidata_item_id: nil
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

  test "full name must be between 3 and 120 characters" do
    # Too short
    attrs = %{full_name: "x"}
    assert {:full_name, "should be at least 3 character(s)"} in errors_on(%Speaker{}, attrs)

    # Too long
    attrs = %{full_name: String.duplicate("x", 121)}
    assert {:full_name, "should be at most 120 character(s)"} in errors_on(%Speaker{}, attrs)
  end

  test "title must be between 3 and 240 characters" do
    # Too short
    attrs = %{title: "x"}
    assert {:title, "should be at least 3 character(s)"} in errors_on(%Speaker{}, attrs)

    # Too long
    attrs = %{title: String.duplicate("x", 241)}
    assert {:title, "should be at most 240 character(s)"} in errors_on(%Speaker{}, attrs)
  end

  test "name and title are trimmed" do
    changeset = Speaker.changeset(%Speaker{}, Map.put(@valid_attrs, :full_name, "   Hector    "))
    assert changeset.changes.full_name == "Hector"

    changeset =
      Speaker.changeset(%Speaker{}, Map.put(@valid_attrs, :title, "   King     of the world    "))

    assert changeset.changes.title == "King of the world"
  end

  describe "wikidata item id" do
    test "reject if bad format" do
      integer_id = %{@valid_attrs | wikidata_item_id: 42}
      missing_q = %{@valid_attrs | wikidata_item_id: "42424242"}
      missing_id = %{@valid_attrs | wikidata_item_id: "Q"}

      assert {:wikidata_item_id, "is invalid"} in errors_on(%Speaker{}, integer_id)
      assert {:wikidata_item_id, "has invalid format"} in errors_on(%Speaker{}, missing_q)
      assert {:wikidata_item_id, "has invalid format"} in errors_on(%Speaker{}, missing_id)
    end

    test "accept correct format and uppercase Q if not already" do
      valid_uppercase = %{@valid_attrs | wikidata_item_id: "Q42"}
      assert Speaker.changeset(%Speaker{}, valid_uppercase).valid?

      valid_lowercase = %{@valid_attrs | wikidata_item_id: "q42"}
      changeset = Speaker.changeset(%Speaker{}, valid_lowercase)
      assert changeset.valid?
      assert changeset.changes.wikidata_item_id == "Q42"
    end
  end
end
