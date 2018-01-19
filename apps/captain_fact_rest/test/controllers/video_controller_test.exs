defmodule CaptainFactREST.VideoControllerTest do
  use CaptainFactREST.ConnCase
  import CaptainFact.Factory

  alias CaptainFact.Videos.Video

  test "GET /videos", %{conn: conn} do
    CaptainFact.Repo.delete_all(Video)
    videos = insert_list(5, :video)
    response =
      conn
      |> get("/videos")
      |> json_response(200)

    random_video = List.first(videos)
    assert Enum.count(videos) == Enum.count(response)
    assert random_video.title == Enum.find(response, &(&1["provider_id"] == random_video.provider_id))["title"]
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