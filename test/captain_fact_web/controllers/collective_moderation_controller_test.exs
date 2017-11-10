defmodule CaptainFactWeb.CollectiveModerationControllerTest do
  use CaptainFactWeb.ConnCase
  import CaptainFact.Factory

  alias CaptainFact.Moderation
  alias CaptainFact.Videos.VideoHashId

  test "GET all reported actions for video" do
    limit = Moderation.nb_flags_to_ban(:create, :comment)
    statement = insert(:statement)
    comment_text = "I like to move it"
    comments =
      Stream.repeatedly(fn -> insert(:comment, %{statement: statement, text: comment_text}) |> with_action() end)
      |> Enum.take(5)

    flag_comments(comments, limit)

    actions =
      build_authenticated_conn(insert(:user, %{reputation: 10000}))
      |> get("/moderation/videos/#{VideoHashId.encode(statement.video_id)}")
      |> json_response(200)

    assert Enum.count(actions) == Enum.count(comments)
    assert hd(actions)["changes"]["text"] == comment_text
  end

  test "need to be authenticated and have enough reputation for all collective moderation actions", %{conn: conn} do
    requests = [
      {&get/3,  "videos/xxxx",  nil},
      {&get/3,  "random",       nil},
      {&post/3, "feedback",     %{"value" => 1, "action_id" => 1}}
    ]

    # Ensure we need to be authenticated
    Enum.map(requests, fn {method, path, args} ->
      assert json_response(method.(conn, "/moderation/" <> path, args), 401) == %{"error" => "unauthorized"}
    end)

    # Ensure we need enough reputation
    new_user = insert(:user, %{reputation: 30})
    authed_conn = build_authenticated_conn(new_user)
    Enum.map(requests, fn {method, path, args} ->
      assert_raise CaptainFact.Accounts.UserPermissions.PermissionsError, fn ->
        method.(authed_conn, "/moderation/" <> path, args)
      end
    end)
  end

  defp flag_comments(comments, nb_flags, reason \\ 1) do
    users = insert_list(nb_flags, :user, %{reputation: 1000})
    Enum.map(comments, fn comment ->
      Enum.map(users, fn user ->
        CaptainFact.Actions.Flagger.flag!(user.id, comment, reason)
      end)
    end)
  end
end