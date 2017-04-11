defmodule CaptainFact.VideoTest do
  use CaptainFact.ModelCase, async: true

  alias CaptainFact.Video
  alias CaptainFact.User

  @valid_attrs %{
    is_private: false,
    title: Faker.Lorem.sentence,
    url: "https://www.youtube.com/watch?v=zoP-XFuWstw",
    owner_id: 1
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

  # ---- Access rights ----

  describe "Access rights" do
    setup do
      owner = %User{id: 42}
      admin = %User{id: 1337}
      regular_user = %User{id: 4242}
      video = %Video{owner_id: owner.id, admins: [admin], is_private: true}
      %{owner: owner, admin: admin, regular_user: regular_user, video: video}
    end

    test "user is admin if owner", %{video: video, owner: owner} do
      assert Video.is_admin(video, owner)
    end

    test "user is admin if present in admins list", %{video: video, admin: admin} do
      assert Video.is_admin(video, admin)
    end

    test "by default user is not admin", %{video: video, regular_user: regular_user} do
      refute Video.is_admin(video, regular_user)
    end

    test "user have access to private video if owner", %{video: video, owner: owner} do
      assert Video.has_access(video, owner)
    end

    test "user have access to private video if admin", %{video: video, admin: admin} do
      assert Video.has_access(video, admin)
    end

    test "by default user doesn't have access to private video", %{video: video, regular_user: regular_user} do
      refute Video.has_access(video, regular_user)
    end
  end

end
