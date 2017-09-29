defmodule CaptainFactWeb.VideoControllerTest do
  use CaptainFactWeb.ConnCase
  import CaptainFact.Factory

  alias CaptainFactWeb.Video

  test "GET /api/videos", %{conn: conn} do
    CaptainFact.Repo.delete_all(Video)
    videos = insert_list(5, :video)
    response =
      conn
      |> get("/api/videos")
      |> json_response(200)

    random_video = List.first(videos)
    assert Enum.count(videos) == Enum.count(response)
    assert random_video.title == Enum.find(response, &(&1["provider_id"] == random_video.provider_id))["title"]
  end

  test "POST /api/videos with invalid url" do
    response =
      build_authenticated_conn(insert(:user))
      |> post("/api/videos", %{url: "https://google.fr"})
      |> json_response(422)

    assert response == %{"error" => %{"url" => "Invalid URL"}}
  end
end