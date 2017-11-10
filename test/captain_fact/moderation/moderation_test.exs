defmodule CaptainFact.ModerationTest do
  use CaptainFact.DataCase
  doctest CaptainFact.Moderation

  alias CaptainFact.Actions.UserAction
  alias CaptainFact.Moderation


  test "returns all actions with number of flags above the limit for given video" do
    limit = Moderation.nb_flags_to_ban(:create, :comment)
    statement = insert(:statement)
    comment_text = "I like to move it"
    comments =
      Stream.repeatedly(fn -> insert(:comment, %{statement: statement, text: comment_text}) |> with_action() end)
      |> Enum.take(5)

    flag_comments(comments, limit)
    actions = Moderation.video(insert(:user, %{reputation: 10000}), statement.video_id)
    assert Enum.count(actions) == Enum.count(comments)
    assert hd(actions).changes.text == comment_text
  end

  test "do not return if number of flags is above the default limit but under specific limit for action / entity" do
    limit = Moderation.nb_flags_to_ban(:update, :statement)
    statement = insert(:statement)
    Stream.repeatedly(fn -> insert(:comment, %{statement: statement}) |> with_action() end)
    |> Enum.take(5)
    |> flag_comments(limit)

    actions = Moderation.video(insert(:user, %{reputation: 10000}), statement.video_id)
    assert Enum.count(actions) == 0
  end

  test "do not return actions for which user already gave a feedback" do
    action_type = UserAction.type(:create)
    action_entity = UserAction.entity(:comment)
    limit = Moderation.nb_flags_to_ban(action_type, action_entity)
    statement = insert(:statement)
    comment = insert(:comment, %{statement: statement}) |> with_action()
    flag_comments([comment], limit)

    action = CaptainFact.Repo.get_by(UserAction, type: action_type, entity: action_entity, entity_id: comment.id)
    user = insert(:user, %{reputation: 10000})
    Moderation.feedback!(user, action.id, 1)

    actions_needing_feedback = Moderation.video(user, statement.video_id)
    assert Enum.count(actions_needing_feedback) == 0
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