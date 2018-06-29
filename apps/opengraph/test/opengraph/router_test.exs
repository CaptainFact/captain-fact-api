defmodule Opengraph.RouterTest do
  use ExUnit.Case

  import Plug.Test
  import DB.Factory

  alias Opengraph.Router

  describe "get /u/:username" do
    test "returns 200 for a valid user" do
      user = insert(:user)

      response =
        conn(:get, "/u/#{user.username}")
        |> Router.call([])

        # TODO investigate random warning
        assert response.status == 200
    end

    test "returns 404 for an unknown user" do
      # best way I know to generate URL
      # compatible random string
      username = Kaur.Secure.generate_api_key()

      response =
        conn(:get, "/u/#{username}")
        |> Router.call([])

      assert response.status == 404
    end

    test "returns valid xml" do
      user = insert(:user)

      %{resp_body: body} =
        conn(:get, "/u/#{user.username}")
        |> Router.call([])

      assert SweetXml.parse(body)
    end

    # TODO add some more specific tests
  end

  describe "get /videos" do
    test "returns 200" do
      response = conn(:get, "/videos", []) |> Router.call([])

      assert response.status == 200
    end

    test "returns valid xml" do
      %{resp_body: body} = conn(:get, "/videos", []) |> Router.call([])

      assert SweetXml.parse(body)
    end
  end

  describe "get /videos/:video_id" do
    setup _ do
      video = insert(:video)

      [
        video: video,
        video_id: DB.Type.VideoHashId.encode(video.id)
      ]
    end

    test "returns 200 for a valid video id", context do
      response = conn(:get, "/videos/#{context[:video_id]}") |> Router.call([])

      assert response.status == 200
    end

    test "returns 404 for other ids" do
      video_id = DB.Type.VideoHashId.encode(4_000_000_000)

      # best way I know to generate URL
      # compatible random string
      response = conn(:get, "videos/#{video_id}") |> Router.call([])

      assert response.status == 404
    end

    test "returns valid xml for a valid video", context do
      %{resp_body: body} = conn(:get, "videos/#{context[:video_id]}") |> Router.call([])

      assert SweetXml.parse(body)
    end
  end
  describe "get /videos/:video_id/history" do
    setup _ do
      video = insert(:video)

      [
        video: video,
        video_id: DB.Type.VideoHashId.encode(video.id)
      ]
    end

    test "returns 200 for a valid video id", context do
      response = conn(:get, "/videos/#{context[:video_id]}/history") |> Router.call([])

      assert response.status == 200
    end

    test "returns 404 for other ids" do
      video_id = DB.Type.VideoHashId.encode(4_000_000_000)

      # best way I know to generate URL
      # compatible random string
      response = conn(:get, "videos/#{video_id}/history") |> Router.call([])

      assert response.status == 404
    end

    test "returns valid xml for a valid video", context do
      %{resp_body: body} = conn(:get, "videos/#{context[:video_id]}/history") |> Router.call([])

      assert SweetXml.parse(body)
    end
  end
end
