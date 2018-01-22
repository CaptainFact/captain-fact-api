defmodule CaptainFactWeb.CollectiveModerationControllerTest do
  use CaptainFactWeb.ConnCase
  import DB.Factory
  import CaptainFact.TestUtils, only: [flag_comments: 2]

  alias DB.Type.VideoHashId
  alias DB.Schema.UserAction
  alias DB.Schema.UserFeedback

  alias CaptainFact.Moderation


  test "GET all reported actions for video" do
    limit = Moderation.nb_flags_report(:create, :comment)
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

  test "GET random actions to verify" do
    Repo.delete_all(UserFeedback)
    limit = Moderation.nb_flags_report(:create, :comment)
    comments = [
      insert(:comment, %{text: "I like to move it...."}) |> with_action(),
      insert(:comment, %{text: "Jouje is the best jouje"}) |> with_action(),
      insert(:comment, %{text: "No problemo, he said"}) |> with_action(),
    ]
    flag_comments(comments, limit)

    actions =
      build_authenticated_conn(insert(:user, %{reputation: 10000}))
      |> get("/moderation/random")
      |> json_response(200)

    assert Enum.count(actions) == Enum.count(comments)
  end

  test "GET random actions can take a count parameter and returns the number of actions specified" do
    limit = Moderation.nb_flags_report(:create, :comment)
    comments = Stream.repeatedly(fn -> insert(:comment) |> with_action() end) |> Enum.take(10)
    flag_comments(comments, limit)
    actions =
      build_authenticated_conn(insert(:user, %{reputation: 10000}))
      |> get("/moderation/random?count=3")
      |> json_response(200)

    assert Enum.count(actions) == 3
  end

  test "POST feedback" do
    Repo.delete_all(UserFeedback)
    limit = Moderation.nb_flags_report(:create, :comment)
    comment = insert(:comment) |> with_action() |> flag(limit)
    action = Repo.get_by! UserAction,
      entity: UserAction.entity(:comment), type: UserAction.type(:create), entity_id: comment.id
    value = 1

    build_authenticated_conn(insert(:user, %{reputation: 10000}))
    |> post("/moderation/feedback", %{"action_id" => action.id, "value" => value})
    |> response(204)

    assert Repo.get_by(UserFeedback, action_id: action.id).value == value
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
end