defmodule CaptainFact.VideosTest do
  use CaptainFact.DataCase

  alias CaptainFact.Videos
  alias CaptainFact.Accounts.UserPermissions.PermissionsError


  defp test_url, do: "__TEST__/#{DB.Utils.TokenGenerator.generate(8)}"

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
      {:ok, video_nil} = Videos.create!(publisher, test_url(), nil)
      {:ok, video_true} = Videos.create!(publisher, test_url(), true)
      {:ok, video_false} = Videos.create!(publisher, test_url(), false)

      assert video_unspecified.is_partner == true
      assert video_nil.is_partner == true
      assert video_true.is_partner == true
      assert video_false.is_partner == false
    end

    test "regular user cannot set is_partner" do
      regular_user = insert(:user, reputation: 50_000)
      {:ok, video} = Videos.create!(regular_user, test_url())
      {:ok, video_2} = Videos.create!(regular_user, test_url(), true)

      assert video.is_partner == false
      assert video_2.is_partner == false
    end
  end
end