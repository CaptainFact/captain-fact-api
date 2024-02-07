defmodule CF.RestApi.VideoDebateChannelTest do
  use CF.RestApi.ChannelCase

  alias CF.RestApi.VideoDebateChannel

  test "Get video info when connecting" do
    video = insert(:video) |> with_video_hash_id()

    {:ok, returned_video, socket} =
      subscribe_and_join(
        socket(CF.RestApi.UserSocket, "", %{user_id: nil}),
        VideoDebateChannel,
        "video_debate:#{video.hash_id}"
      )

    assert returned_video.id == video.id
    assert returned_video.hash_id == video.hash_id
    assert returned_video.url == video.url
    leave(socket)
  end

  test "New speakers get broadcasted" do
    # Init
    video = insert(:video) |> with_video_hash_id()
    topic = "video_debate:#{video.hash_id}"

    {:ok, _, authed_socket} =
      subscribe_and_join(
        socket(CF.RestApi.UserSocket, "", %{user_id: insert(:user, %{reputation: 5000}).id}),
        VideoDebateChannel,
        topic
      )

    # Test
    @endpoint.subscribe("video_debate:#{video.hash_id}")
    speaker = %{full_name: "Titi Toto"}
    ref = push(authed_socket, "new_speaker", speaker)
    assert_reply(ref, :ok, _)
    assert_broadcast("speaker_added", %{full_name: "Titi Toto"})

    # Cleanup
    leave(authed_socket)
  end
end
