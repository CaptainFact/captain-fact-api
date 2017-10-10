defmodule CaptainFact.Actions.FlaggerTest do
  use CaptainFact.DataCase

  alias CaptainFact.Actions.Flagger
  alias CaptainFact.Actions.Analysers.{Flags, Reputation}
  alias CaptainFact.Accounts.User
  alias CaptainFactWeb.Flag
  alias CaptainFact.Comments.Comment


  setup do
    Repo.delete_all(Flag)
    Repo.delete_all(User)
    target_user = insert(:user, %{reputation: 10000})
    comment = insert(:comment, %{user: target_user})
    source_users = insert_list(Flags.comments_nb_flags_to_ban, :user, %{reputation: 10000})
    {:ok, [source_users: source_users, target_user: target_user, comment: comment]}
  end

  test "flags get inserted in DB and user looses reputation", context do
    source = List.first(context[:source_users])
    comment = context[:comment]

    Flagger.flag!(comment, 1, source.id)
    Reputation.update()
    Flags.update()
    assert Flagger.get_nb_flags(comment) == 1
    assert Repo.get!(User, context[:target_user].id).reputation < context[:target_user].reputation
  end

  test "comment banned after x flags and user looses reputation", context do
    comment = context[:comment]
    target = context[:target_user]

    for source <- context[:source_users] do
      Flagger.flag!(comment, 1, source.id)
    end
    Reputation.update()
    Flags.update()
    assert Repo.get(Comment, comment.id).is_banned == true
    assert Repo.get!(User, target.id).reputation < target.reputation
  end
end
