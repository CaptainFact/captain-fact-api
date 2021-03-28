defmodule DB.Schema.VideoTest do
  use DB.DataCase, async: true
  doctest DB.Schema.Video

  alias DB.Schema.Video

  @valid_attrs %{
    title: Faker.Lorem.sentence(),
    url: "https://www.youtube.com/watch?v=zoP-XFuWstw"
  }

  # ---- Schema ----

  describe "Changesets" do
    test "video is valid with valid attributes" do
      changeset = Video.changeset(%Video{}, @valid_attrs)
      assert changeset.valid?
    end

    test "url can be a short youtube url" do
      attrs = Map.put(@valid_attrs, :url, "https://youtu.be/i92WEKROND8")
      changeset = Video.changeset(%Video{}, attrs)
      assert changeset.valid?
    end

    test "video is not valid with missing attributes" do
      changeset = Video.changeset(%Video{}, %{})
      refute changeset.valid?
    end

    test "url must be properly formatted" do
      attrs = Map.put(@valid_attrs, :url, "BAD URL !")
      changeset = Video.changeset(%Video{}, attrs)
      refute changeset.valid?
    end

    test "title must be between 5 and 120 characters" do
      # Too short
      attrs = %{title: "x"}
      assert {:title, "should be at least 5 character(s)"} in errors_on(%Video{}, attrs)

      # Too long
      attrs = %{title: String.duplicate("x", 121)}
      assert {:title, "should be at most 120 character(s)"} in errors_on(%Video{}, attrs)
    end

    test "unknown or invalid language gives nil values but aren't rejected" do
      attrs = Map.put(@valid_attrs, :language, "zxx")
      changeset = Video.changeset(%Video{}, attrs)
      assert changeset.valid?
      assert changeset.changes["language"] == nil

      attrs = Map.put(@valid_attrs, :language, "xxx-zzz-fff")
      changeset = Video.changeset(%Video{}, attrs)
      assert changeset.valid?
      assert changeset.changes["language"] == nil
    end

    test "valid locale is stored" do
      attrs = Map.put(@valid_attrs, :language, "fr")
      changeset = Video.changeset(%Video{}, attrs)
      assert changeset.valid?
      assert changeset.changes.language == "fr"

      attrs = Map.put(@valid_attrs, :language, "en-US")
      changeset = Video.changeset(%Video{}, attrs)
      assert changeset.valid?
      assert changeset.changes.language == "en"
    end
  end
end
