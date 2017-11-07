defmodule CaptainFact.ModerationTest do
  use CaptainFact.DataCase
  doctest CaptainFact.Moderation

  alias CaptainFact.Moderation


  test "returns all actions with number of flags above the limit for given video" do
    limit = Moderation.nb_flags_to_ban(:create, :comment)
    statement = insert(:statement)
    comment_text = "I like to move it"
    comments =
      Stream.repeatedly(fn -> insert(:comment, %{statement: statement, text: comment_text}) |> with_action() end)
      |> Enum.take(5)

    flag_comments(comments, limit)
    actions = Moderation.video(statement.video_id)
    assert Enum.count(actions) == Enum.count(comments)
    assert hd(actions).changes.text == comment_text
  end

  test "do not return if number of flags is above the default limit but under specific limit for action / entity" do
    limit = Moderation.nb_flags_to_ban(:update, :statement)
    statement = insert(:statement)
    Stream.repeatedly(fn -> insert(:comment, %{statement: statement}) |> with_action() end)
    |> Enum.take(5)
    |> flag_comments(limit)

    actions = Moderation.video(statement.video_id)
    assert Enum.count(actions) == 0
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