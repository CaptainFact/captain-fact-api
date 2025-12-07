defmodule CF.Graphql.SubscriptionEventsTest do
  use CF.Graphql.ConnCase, async: false
  use Absinthe.Phoenix.SubscriptionTest, schema: CF.Graphql.Schema

  alias CF.Graphql.Subscriptions

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
        variables: %{"videoId" => 123}
      )

    assert_reply(ref, :ok, %{subscriptionId: subscription_id})

    statement = %DB.Schema.Statement{
      id: 1,
      video_id: 123,
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
      subscriptionId: subscription_id
    })
  end
end

