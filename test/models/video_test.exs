defmodule CaptainFact.VideoTest do
  use CaptainFact.ModelCase, async: true

  alias CaptainFact.Video

  @valid_attrs %{
    title: Faker.Lorem.sentence,
    url: "https://www.youtube.com/watch?v=zoP-XFuWstw"
  }

  # ---- Schema ----

  describe "Changesets" do
    test "video is valid with valid attributes" do
      changeset = Video.changeset(%Video{}, @valid_attrs)
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
  end
end
