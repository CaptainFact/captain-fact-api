defmodule CF.Graphql.SubscriptionEventsTest do
  use CF.Graphql.ConnCase, async: false
  use Absinthe.Phoenix.SubscriptionTest, schema: CF.Graphql.Schema

  import Phoenix.ChannelTest

  alias CF.Graphql.Subscriptions
  alias DB.Schema.{Comment, Speaker, UserAction, Video}

  @video_id 123

  setup do
    {:ok, socket} = Phoenix.ChannelTest.connect(CF.GraphQLWeb.UserSocket, %{})
    {:ok, socket} = join_absinthe(socket)

    {:ok, socket: socket}
  end

  test "statementAdded publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          statementAdded(videoId: $videoId) {
            id
            text
            time
            isDraft
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    statement = %DB.Schema.Statement{
      id: 1,
      video_id: @video_id,
      text: "Hello world",
      time: 10,
      is_draft: false
    }

    Subscriptions.publish_statement_added(statement)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "statementAdded" => %{
            "id" => "1",
            "text" => "Hello world",
            "time" => 10,
            "isDraft" => false
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "statementUpdated publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          statementUpdated(videoId: $videoId) {
            id
            text
            time
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    statement = %DB.Schema.Statement{
      id: 2,
      video_id: @video_id,
      text: "Updated",
      time: 20,
      is_draft: false
    }

    Subscriptions.publish_statement_updated(statement)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "statementUpdated" => %{
            "id" => "2",
            "text" => "Updated",
            "time" => 20
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "statementRemoved publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          statementRemoved(videoId: $videoId) {
            id
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    Subscriptions.publish_statement_removed(99, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "statementRemoved" => %{
            "id" => "99"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "commentAdded publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          commentAdded(videoId: $videoId) {
            id
            text
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    comment = %Comment{
      id: 5,
      statement_id: 1,
      text: "A comment",
      inserted_at: ~N[2024-06-01 12:00:00],
      updated_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_comment_added(comment, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "commentAdded" => %{
            "id" => "5",
            "text" => "A comment"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "commentUpdated publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          commentUpdated(videoId: $videoId) {
            id
            text
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    comment = %Comment{
      id: 6,
      statement_id: 1,
      text: "Edited",
      inserted_at: ~N[2024-06-01 12:00:00],
      updated_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_comment_updated(comment, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "commentUpdated" => %{
            "id" => "6",
            "text" => "Edited"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "commentRemoved publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          commentRemoved(videoId: $videoId) {
            id
            statementId
            replyToId
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    comment = %Comment{
      id: 7,
      statement_id: 3,
      reply_to_id: 2,
      inserted_at: ~N[2024-06-01 12:00:00],
      updated_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_comment_removed(comment, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "commentRemoved" => %{
            "id" => "7",
            "statementId" => "3",
            "replyToId" => "2"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "commentScoreDiff publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          commentScoreDiff(videoId: $videoId) {
            diff
            comment {
              id
              statementId
            }
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    comment = %Comment{
      id: 8,
      statement_id: 4,
      reply_to_id: nil,
      inserted_at: ~N[2024-06-01 12:00:00],
      updated_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_comment_score_diff(comment, 2, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "commentScoreDiff" => %{
            "diff" => 2,
            "comment" => %{
              "id" => "8",
              "statementId" => "4"
            }
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "videoUpdated publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          videoUpdated(videoId: $videoId) {
            id
            title
            hashId
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    video = %Video{
      id: @video_id,
      hash_id: "ab12cd34",
      title: "Video title",
      youtube_id: "abcdefghijk",
      unlisted: false,
      youtube_offset: 0,
      facebook_offset: 0,
      inserted_at: ~U[2024-06-01 12:00:00Z],
      updated_at: ~U[2024-06-01 12:00:00Z]
    }

    Subscriptions.publish_video_updated(video)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "videoUpdated" => %{
            "id" => "123",
            "title" => "Video title",
            "hashId" => "ab12cd34"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "speakerAdded publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          speakerAdded(videoId: $videoId) {
            id
            fullName
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    speaker = %Speaker{
      id: 10,
      full_name: "Jane Doe",
      inserted_at: ~N[2024-06-01 12:00:00],
      updated_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_speaker_added(speaker, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "speakerAdded" => %{
            "id" => "10",
            "fullName" => "Jane Doe"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "speakerUpdated publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          speakerUpdated(videoId: $videoId) {
            id
            fullName
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    speaker = %Speaker{
      id: 11,
      full_name: "John Doe",
      inserted_at: ~N[2024-06-01 12:00:00],
      updated_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_speaker_updated(speaker, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "speakerUpdated" => %{
            "id" => "11",
            "fullName" => "John Doe"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "speakerRemoved publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          speakerRemoved(videoId: $videoId) {
            id
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    Subscriptions.publish_speaker_removed(12, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "speakerRemoved" => %{
            "id" => "12"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "videoHistoryActionAdded publishes payload to subscribers", %{socket: socket} do
    ref =
      push_doc(
        socket,
        """
        subscription($videoId: ID!) {
          videoHistoryActionAdded(videoId: $videoId) {
            id
            type
            entity
          }
        }
        """,
        variables: %{"videoId" => @video_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    action = %UserAction{
      id: 100,
      user_id: 1,
      type: :create,
      entity: :statement,
      video_id: @video_id,
      inserted_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_video_history_action(action, @video_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "videoHistoryActionAdded" => %{
            "id" => "100",
            "type" => "create",
            "entity" => "statement"
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end

  test "statementHistoryActionAdded publishes payload to subscribers", %{socket: socket} do
    statement_id = 55

    ref =
      push_doc(
        socket,
        """
        subscription($statementId: ID!) {
          statementHistoryActionAdded(statementId: $statementId) {
            id
            type
            entity
            statementId
          }
        }
        """,
        variables: %{"statementId" => statement_id}
      )

    assert_reply(ref, :ok, reply)
    %{subscriptionId: sub_id} = reply

    action = %UserAction{
      id: 101,
      user_id: 1,
      type: :update,
      entity: :statement,
      statement_id: statement_id,
      inserted_at: ~N[2024-06-01 12:00:00]
    }

    Subscriptions.publish_statement_history_action(action, statement_id)

    assert_push("subscription:data", %{
      result: %{
        data: %{
          "statementHistoryActionAdded" => %{
            "id" => "101",
            "type" => "update",
            "entity" => "statement",
            "statementId" => 55
          }
        }
      },
      subscriptionId: ^sub_id
    })
  end
end
