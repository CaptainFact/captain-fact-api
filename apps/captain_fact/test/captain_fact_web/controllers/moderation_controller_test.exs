defmodule CaptainFactWeb.ModerationControllerTest do
  use CaptainFactWeb.ConnCase
  import DB.Factory
  import CaptainFact.TestUtils, only: [flag_comments: 2]

  alias DB.Schema.UserAction
  alias DB.Schema.ModerationUserFeedback

  alias CaptainFact.Moderation

  test "GET random action to verify" do
    Repo.delete_all(ModerationUserFeedback)
    limit = Moderation.nb_flags_to_report(:create, :comment)
    comment = insert(:comment, %{text: "Jouje is the best jouje"}) |> with_action()
    flag_comments([comment], limit)

    response =
      :user
      |> insert(%{reputation: 10_000})
      |> build_authenticated_conn()
      |> get("/moderation/random")
      |> json_response(200)

    assert response["action"]["commentId"] == comment.id
  end

  test "POST feedback" do
    Repo.delete_all(ModerationUserFeedback)
    limit = Moderation.nb_flags_to_report(:create, :comment)
    comment = insert(:comment) |> with_action() |> flag(limit)

    action =
      Repo.get_by!(
        UserAction,
        entity: UserAction.entity(:comment),
        type: UserAction.type(:create),
        comment_id: comment.id
      )

    value = 1

    :user
    |> insert(%{reputation: 10_000})
    |> build_authenticated_conn()
    |> post("/moderation/feedback", %{
      "action_id" => action.id,
      "value" => value,
      "reason" => 1
    })
    |> response(204)

    assert Repo.get_by(ModerationUserFeedback, action_id: action.id).value == value
  end

  test "need to be authenticated to access moderation", %{conn: conn} do
    request = get(conn, "/moderation/random")

    assert json_response(request, 401) == %{"error" => "unauthorized"}
  end

  test "need to be authenticated to feedback on moderation", %{conn: conn} do
    args = %{"value" => 1, "action_id" => 1, "reason" => 1}
    request = post(conn, "/moderation/feedback", args)

    assert json_response(request, 401) == %{"error" => "unauthorized"}
  end

  test "need to have enough reputation to access moderation" do
    new_user = insert(:user, %{reputation: 30})
    authed_conn = build_authenticated_conn(new_user)

    make_request = fn ->
      get(authed_conn, "/moderation/random")
    end

    assert_raise(
      CaptainFact.Accounts.UserPermissions.PermissionsError,
      make_request
    )
  end

  test "need to have enough reputation to feedback on moderation" do
    new_user = insert(:user, %{reputation: 30})
    authed_conn = build_authenticated_conn(new_user)

    make_request = fn ->
      post(authed_conn, "moderation/feedback", %{"value" => 1, "action_id" => 1, "reason" => 1})
    end

    assert_raise(
      CaptainFact.Accounts.UserPermissions.PermissionsError,
      make_request
    )
  end
end
