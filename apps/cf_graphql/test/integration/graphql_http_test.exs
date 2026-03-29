defmodule CF.Graphql.GraphqlHttpTest do
  use CF.Graphql.ConnCase

  test "appInfo query returns schema metadata", %{conn: conn} do
    query = "{ appInfo { status version dbVersion } }"

    conn = graphql_post(conn, query)
    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)
    assert body["errors"] == nil
    info = body["data"]["appInfo"]
    assert info["status"] == "✔"
    assert is_binary(info["version"])
    assert is_binary(info["dbVersion"])
  end

  test "videos query returns paginated structure", %{conn: conn} do
    query = "{ videos(offset: 1, limit: 5) { totalEntries entries { id } } }"

    conn = graphql_post(conn, query)
    assert conn.status == 200

    body = Jason.decode!(conn.resp_body)
    assert body["errors"] == nil
    assert %{"entries" => _, "totalEntries" => _} = body["data"]["videos"]
  end

  test "loggedInUser is null without authorization", %{conn: conn} do
    query = "{ loggedInUser { id } }"

    conn = graphql_post(conn, query)
    body = Jason.decode!(conn.resp_body)
    assert body["errors"] == nil
    assert body["data"]["loggedInUser"] == nil
  end

  test "loggedInUser returns user when authorized", _ do
    user = insert(:user)
    query = "{ loggedInUser { id username } }"

    conn =
      user
      |> build_authenticated_conn()
      |> graphql_post(query)

    body = Jason.decode!(conn.resp_body)
    assert body["errors"] == nil
    assert body["data"]["loggedInUser"]["username"] == user.username
    assert body["data"]["loggedInUser"]["id"] == to_string(user.id)
  end

  test "user query by username returns public profile", %{conn: conn} do
    u = insert(:user, username: "graphql_http_test_user")

    query = """
    query($name: String!) {
      user(username: $name) { id username }
    }
    """

    conn = graphql_post(conn, query, %{"name" => u.username})
    body = Jason.decode!(conn.resp_body)
    assert body["errors"] == nil
    assert body["data"]["user"]["username"] == u.username
  end

  test "mutation requiring auth returns unauthorized when anonymous", %{conn: conn} do
    query = """
    mutation {
      updateNotifications(ids: [], seen: true) { id }
    }
    """

    conn = graphql_post(conn, query)
    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert [%{"message" => "unauthorized"} | _] = body["errors"]
  end

  test "mutation requiring reputation returns error when reputation too low", _ do
    user = insert(:user, reputation: 0)
    video = insert(:video)

    query = """
    mutation($id: ID!, $unlisted: Boolean!) {
      editVideo(id: $id, unlisted: $unlisted) { id }
    }
    """

    conn =
      user
      |> build_authenticated_conn()
      |> graphql_post(query, %{"id" => to_string(video.id), "unlisted" => true})

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    [err | _] = body["errors"]

    assert err["message"] ==
             "You do not have the required reputation to perform this action."
  end

  test "createStatement succeeds when authenticated with sufficient permissions", _ do
    user = insert(:user, reputation: 30)
    video = insert(:video)

    query = """
    mutation($videoId: ID!, $text: String!, $time: Int!) {
      createStatement(videoId: $videoId, text: $text, time: $time) {
        id
        text
      }
    }
    """

    conn =
      user
      |> build_authenticated_conn()
      |> graphql_post(query, %{
        "videoId" => to_string(video.id),
        "text" => "This statement has at least ten characters.",
        "time" => 42
      })

    body = Jason.decode!(conn.resp_body)
    assert body["errors"] == nil

    assert body["data"]["createStatement"]["text"] ==
             "This statement has at least ten characters."
  end
end
