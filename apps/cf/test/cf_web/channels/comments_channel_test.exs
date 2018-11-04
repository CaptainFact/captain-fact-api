defmodule CF.Web.CommentsChannelTest do
  use CF.Web.ChannelCase, async: false

  alias CF.Web.CommentsChannel

  @nb_comments 3

  setup do
    video = with_video_hash_id(insert(:video))
    statement = insert(:statement, video: video)
    comments = insert_list(@nb_comments, :comment, statement: statement)
    topic = "comments:video:#{video.hash_id}"

    [video: video, statement: statement, comments: comments, topic: topic]
  end

  test "Get comments when connecting", %{comments: comments, topic: topic} do
    {:ok, response, _} = subscribe_and_join(socket("", %{user_id: nil}), CommentsChannel, topic)

    assert Enum.count(response.comments) == Enum.count(comments)
  end

  describe "Comments score update" do
    setup %{topic: topic} do
      user = insert(:user, %{reputation: 50000})

      # Connect to socket
      {:ok, _, socket} =
        subscribe_and_join(
          socket("", %{user_id: user.id}),
          CommentsChannel,
          topic
        )

      @endpoint.subscribe(topic)

      # Leave socket when test exit
      on_exit(fn ->
        leave(socket)
      end)

      [user: user, socket: socket]
    end

    test "with positive value and no previous value", %{comments: comments, socket: socket} do
      comment = List.first(comments)
      payload = %{"comment_id" => comment.id, "value" => 1}
      response = push(socket, "vote", payload)
      assert_reply(response, :ok, _)
      assert_broadcast_diff(comment, 1)
    end

    test "with negative value and no previous value", %{comments: comments, socket: socket} do
      comment = List.first(comments)
      payload = %{"comment_id" => comment.id, "value" => -1}
      response = push(socket, "vote", payload)
      assert_reply(response, :ok, _)
      assert_broadcast_diff(comment, -1)
    end

    test "with no value and no previous value", %{comments: comments, socket: socket} do
      comment = List.first(comments)
      payload = %{"comment_id" => comment.id, "value" => 0}
      response = push(socket, "vote", payload)
      assert_reply(response, :error, _)
    end

    test "with negative value after positive value", %{comments: comments, socket: socket} do
      comment = List.first(comments)
      response1 = push(socket, "vote", %{"comment_id" => comment.id, "value" => 1})
      response2 = push(socket, "vote", %{"comment_id" => comment.id, "value" => -1})
      assert_reply(response1, :ok, _)
      assert_reply(response2, :ok, _)
      assert_broadcast_diff(comment, 1)
      assert_broadcast_diff(comment, -2)
    end

    test "with positive value after negative value", %{comments: comments, socket: socket} do
      comment = List.first(comments)
      response1 = push(socket, "vote", %{"comment_id" => comment.id, "value" => -1})
      response2 = push(socket, "vote", %{"comment_id" => comment.id, "value" => 1})
      assert_reply(response1, :ok, _)
      assert_reply(response2, :ok, _)
      assert_broadcast_diff(comment, -1)
      assert_broadcast_diff(comment, 2)
    end

    test "with no value after negative value", %{comments: comments, socket: socket} do
      comment = List.first(comments)
      response1 = push(socket, "vote", %{"comment_id" => comment.id, "value" => -1})
      response2 = push(socket, "vote", %{"comment_id" => comment.id, "value" => 0})
      assert_reply(response1, :ok, _)
      assert_reply(response2, :ok, _)
      assert_broadcast_diff(comment, -1)
      assert_broadcast_diff(comment, 1)
    end

    test "with no value after positive value", %{comments: comments, socket: socket} do
      comment = List.first(comments)
      response1 = push(socket, "vote", %{"comment_id" => comment.id, "value" => 1})
      response2 = push(socket, "vote", %{"comment_id" => comment.id, "value" => 0})
      assert_reply(response1, :ok, _)
      assert_reply(response2, :ok, _)
      assert_broadcast_diff(comment, 1)
      assert_broadcast_diff(comment, -1)
    end

    defp assert_broadcast_diff(comment, diff) do
      %{id: comment_id, statement_id: statement_id, reply_to_id: reply_to_id} = comment

      assert_broadcast("comment_score_diff", %{
        comment: %{
          id: ^comment_id,
          statement_id: ^statement_id,
          reply_to_id: ^reply_to_id
        },
        diff: ^diff
      })
    end
  end
end
