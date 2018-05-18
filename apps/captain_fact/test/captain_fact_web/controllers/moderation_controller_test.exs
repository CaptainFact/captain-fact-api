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

    assert response["action"]["entity_id"] == comment.id
  end

  test "POST feedback" do
    Repo.delete_all(ModerationUserFeedback)
    limit = Moderation.nb_flags_to_report(:create, :comment)
    comment = insert(:comment) |> with_action() |> flag(limit)
    action = Repo.get_by! UserAction,
      entity: UserAction.entity(:comment), type: UserAction.type(:create), entity_id: comment.id
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

  test "need to be authenticated and have enough reputation for all collective moderation actions", %{conn: conn} do
    requests = [
      {&get/3,  "random",       nil},
      {&post/3, "feedback",     %{"value" => 1, "action_id" => 1, "reason" => 1}}
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