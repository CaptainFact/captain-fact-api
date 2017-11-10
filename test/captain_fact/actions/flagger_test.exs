defmodule CaptainFact.Actions.FlaggerTest do
  use CaptainFact.DataCase

  alias CaptainFact.Actions.{Flagger, Flag}
  alias CaptainFact.Actions.Analyzers.{Flags, Reputation}
  alias CaptainFact.Accounts.User
  alias CaptainFact.Comments.Comment


  setup do
    Repo.delete_all(Flag)
    Repo.delete_all(User)
    target_user = insert(:user, %{reputation: 10000})
    comment = insert(:comment, %{user: target_user}) |> with_action
    source_users = insert_list(Flags.comments_nb_flags_to_ban, :user, %{reputation: 10000})
    {:ok, [source_users: source_users, target_user: target_user, comment: comment]}
  end

  test "flags get inserted in DB", context do
    source = List.first(context[:source_users])
    comment = context[:comment]

    Flagger.flag!(source.id, comment, 1)
    Reputation.update()
    Flags.update()
    assert Flagger.get_nb_flags(comment) == 1
  end

  test "comment banned after x flags", context do
    comment = context[:comment]

    for source <- context[:source_users], do: Flagger.flag!(source.id, comment, 1)
    Reputation.update()
    Flags.update()
    assert Repo.get(Comment, comment.id).is_banned == true
  end
end
