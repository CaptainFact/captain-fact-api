defmodule CaptainFactWeb.VideoControllerTest do
  use CaptainFactWeb.ConnCase
  import DB.Factory

  alias DB.Schema.Video

  describe "GET /videos" do
    test "Returns all videos", %{conn: conn} do
      DB.Repo.delete_all(Video)
      videos = insert_list(5, :video)
      response =
        conn
        |> get("/videos")
        |> json_response(200)

      random_video = List.first(videos)
      assert Enum.count(videos) == Enum.count(response)
      assert random_video.title == Enum.find(response, &(&1["provider_id"] == random_video.provider_id))["title"]
    end

    test "filter on language", %{conn: conn} do
      DB.Repo.delete_all(Video)
      videos_fr = insert_list(2, :video, language: "fr")
      videos_en = insert_list(3, :video, language: "en")
      videos_nil = insert_list(4, :video, language: nil)
      all_videos = videos_fr ++ videos_en ++ videos_nil

      response_fr = json_response(get(conn, "/videos", %{"language" => "fr"}), 200)
      response_en = json_response(get(conn, "/videos", %{"language" => "en"}), 200)
      response_unknown = json_response(get(conn, "/videos", %{"language" => "unknown"}), 200)
      response_nil = json_response(get(conn, "/videos"), 200)

      assert Enum.count(response_fr) == Enum.count(videos_fr)
      assert Enum.count(response_en) == Enum.count(videos_en)
      assert Enum.count(response_unknown) == Enum.count(videos_nil)
      assert Enum.count(response_nil) == Enum.count(all_videos)

      assert List.first(response_fr)["language"] == "fr"
      assert List.first(response_en)["language"] == "en"
      assert List.first(response_unknown)["language"] == nil
    end

    test "filter on is_partner", %{conn: conn} do
      DB.Repo.delete_all(Video)

      videos_community = insert_list(3, :video, is_partner: false)
      videos_partners = insert_list(2, :video, is_partner: true)

      response_community = json_response(get(conn, "/videos", %{"is_partner" => false}), 200)
      response_partners = json_response(get(conn, "/videos", %{"is_partner" => true}), 200)

      assert Enum.count(response_community) == Enum.count(videos_community)
      assert Enum.count(response_partners) == Enum.count(videos_partners)

      assert List.first(response_community)["is_partner"] == false
      assert List.first(response_partners)["is_partner"] == true
    end
  end

  test "POST /videos with invalid url" do
    response =
      insert(:user, %{reputation: 5000})
      |> build_authenticated_conn()
      |> post("/videos", %{url: "https://google.fr"})
      |> json_response(422)

    assert response == %{"error" => %{"url" => "Invalid URL"}}
  end
end