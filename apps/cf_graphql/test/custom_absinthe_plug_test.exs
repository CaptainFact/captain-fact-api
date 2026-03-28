defmodule CF.Graphql.CustomAbsinthePlugTest do
  use CF.Graphql.ConnCase

  test "GraphQL validation error returns 200 JSON with errors array", %{conn: conn} do
    query = "{ __invalid"

    conn = graphql_post(conn, query)

    assert conn.status == 200
    assert ["application/json; charset=utf-8"] = get_resp_header(conn, "content-type")

    body = Jason.decode!(conn.resp_body)
    assert is_list(body["errors"])
    assert body["errors"] != []
  end

  test "authenticated mutation without bearer returns unauthorized GraphQL error", %{conn: conn} do
    query = """
    mutation {
      voteComment(commentId: "1", value: 1) {
        id
      }
    }
    """

    conn = graphql_post(conn, query)

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)
    assert [%{"message" => "unauthorized"} | _] = body["errors"]
  end

  test "PermissionsError from resolver returns FORBIDDEN extension", _ctx do
    user = insert(:user, reputation: -30)
    video = insert(:video)

    query = """
    mutation($videoId: ID!, $text: String!, $time: Int!) {
      createStatement(videoId: $videoId, text: $text, time: $time) {
        id
      }
    }
    """

    conn =
      user
      |> build_authenticated_conn()
      |> graphql_post(query, %{
        "videoId" => to_string(video.id),
        "text" => "Test",
        "time" => 1
      })

    assert conn.status == 200
    body = Jason.decode!(conn.resp_body)

    assert body["data"] == nil
    [err | _] = body["errors"]
    assert err["extensions"]["code"] == "FORBIDDEN"
    assert err["message"] == "not_enough_reputation"
  end
end
