defmodule CaptainFactWeb.VideoControllerTest do
  use CaptainFactWeb.ConnCase
  import CaptainFact.Factory

  alias CaptainFactWeb.Video

  setup do
    CaptainFact.Repo.delete_all(Video)
    :ok
  end

  test "GET /api/videos", %{conn: conn} do
    videos = for _ <- 0..5, do: insert(:video)
    response =
      conn
      |> get("/api/videos")
      |> json_response(200)

    assert Enum.count(videos) == Enum.count(response)
  end
end