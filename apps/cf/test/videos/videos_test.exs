defmodule CF.VideosTest do
  use CF.DataCase

  alias DB.Type.VideoHashId
  alias CF.Videos
  alias CF.Accounts.UserPermissions.PermissionsError

  defp test_url, do: "https://www.youtube.com/watch?v=#{DB.Utils.TokenGenerator.generate(11)}"

  describe "Add video" do
    test "without enough reputation" do
      user = insert(:user, reputation: 0, is_publisher: false)

      assert_raise PermissionsError, fn ->
        Videos.create!(user, test_url())
      end
    end

    test "with enough reputation" do
      user = insert(:user, reputation: 50_000)
      {:ok, _video} = Videos.create!(user, test_url())
    end

    test "fetch metadata" do
      user = insert(:user, is_publisher: true)
      {:ok, video} = Videos.create!(user, test_url())
      assert video.title == "__TEST-TITLE__"
    end

    test "set is_partner to true if publisher unless specified otherwise" do
      publisher = insert(:user, is_publisher: true)

      {:ok, video_unspecified} = Videos.create!(publisher, test_url())
      {:ok, video_nil} = Videos.create!(publisher, test_url(), is_partner: nil)
      {:ok, video_true} = Videos.create!(publisher, test_url(), is_partner: true)
      {:ok, video_false} = Videos.create!(publisher, test_url(), is_partner: false)

      assert video_unspecified.is_partner == true
      assert video_nil.is_partner == true
      assert video_true.is_partner == true
      assert video_false.is_partner == false
    end

    test "regular user cannot set is_partner" do
      regular_user = insert(:user, reputation: 50_000)
      {:ok, video} = Videos.create!(regular_user, test_url())
      {:ok, video_2} = Videos.create!(regular_user, test_url(), is_partner: true)

      assert video.is_partner == false
      assert video_2.is_partner == false
    end

    test "properly insert VideoHashId" do
      user = insert(:user, reputation: 50_000)
      {:ok, video} = Videos.create!(user, test_url())
      assert video.hash_id == VideoHashId.encode(video.id)
    end
  end

  describe "Fetch captions" do
    test "fetch captions" do
      video =
        DB.Factory.insert(
          :video,
          youtube_id: DB.Utils.TokenGenerator.generate(11),
          language: "en"
        )

      {:ok, captions} = Videos.download_captions(video)

      assert captions.raw == "__TEST-CONTENT__"

      assert captions.parsed == [
               %{
                 "text" => "__TEST-CONTENT__",
                 "start" => 0.0,
                 "duration" => 1.0
               }
             ]
    end
  end
end
