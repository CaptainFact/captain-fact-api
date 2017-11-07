defmodule CaptainFactWeb.CollectiveModerationControllerTest do
  use CaptainFactWeb.ConnCase
  import CaptainFact.Factory

  alias CaptainFact.Moderation
  alias CaptainFact.Videos.VideoHashId

  test "GET all reported actions for video", %{conn: conn} do
    limit = Moderation.nb_flags_to_ban(:create, :comment)
    statement = insert(:statement)
    comment_text = "I like to move it"
    comments =
      Stream.repeatedly(fn -> insert(:comment, %{statement: statement, text: comment_text}) |> with_action() end)
      |> Enum.take(5)

    flag_comments(comments, limit)

    actions =
      conn
      |> get("/moderation/videos/#{VideoHashId.encode(statement.video_id)}")
      |> json_response(200)

    assert Enum.count(actions) == Enum.count(comments)
    assert hd(actions)["changes"]["text"] == comment_text
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