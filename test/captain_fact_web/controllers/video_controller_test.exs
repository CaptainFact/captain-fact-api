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

    assert Enum.count(videos) == Enum.count(response)
  end
end