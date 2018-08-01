defmodule CaptainFactWeb.VideoDebateChannelTest do
  use CaptainFactWeb.ChannelCase
  alias CaptainFactWeb.VideoDebateChannel
  alias DB.Type.VideoHashId

  test "Get video info when connecting" do
    video = insert(:video)
    encoded_id = VideoHashId.encode(video.id)

    {:ok, returned_video, socket} =
      subscribe_and_join(
        socket("", %{user_id: nil}),
        VideoDebateChannel,
        "video_debate:#{encoded_id}"
      )

    assert returned_video.id == encoded_id
    assert returned_video.url == video.url
    leave(socket)
  end

  test "New speakers get broadcasted" do
    # Init
    topic = "video_debate:#{VideoHashId.encode(insert(:video).id)}"

    {:ok, _, authed_socket} =
      subscribe_and_join(
        socket("", %{user_id: insert(:user, %{reputation: 5000}).id}),
        VideoDebateChannel,
        topic
      )

    # Test
    @endpoint.subscribe("video_debate:#{VideoHashId.encode(insert(:video).id)}")
    speaker = %{full_name: "Titi Toto"}
    ref = push(authed_socket, "new_speaker", speaker)
    assert_reply(ref, :ok, _)
    assert_broadcast("speaker_added", %{full_name: "Titi Toto"})

    # Cleanup
    leave(authed_socket)
  end
end
