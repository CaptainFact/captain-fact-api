defmodule CaptainFact.FlaggerTest do
  use ExUnit.Case, async: false

  import CaptainFact.Factory

  alias CaptainFact.Flagger
  alias CaptainFact.Repo
  alias CaptainFact.Accounts.User
  alias CaptainFactWeb.{Flag, Comment}

  setup do
    Repo.delete_all(Flag)
    :ok
  end

  setup_all do
    Repo.delete_all(Flag)
    Repo.delete_all(User)
    target_user = insert(:user, %{reputation: 10000})
    comment = insert(:comment, %{user: target_user})
    source_users = insert_list(Flagger.comments_nb_flags_to_ban, :user, %{reputation: 10000})
    {:ok, [source_users: source_users, target_user: target_user, comment: comment]}
  end

  test "flags get inserted in DB and user looses reputation", context do
    source = List.first(context[:source_users])
    comment = context[:comment]

    Flagger.flag!(comment, 1, source.id, false)
    assert Flagger.get_nb_flags(comment) == 1
    assert Repo.get!(User, context[:target_user].id).reputation < context[:target_user].reputation
  end

  test "comment banned after x flags and user looses reputation", context do
    comment = context[:comment]
    target = context[:target_user]

    for source <- context[:source_users] do
      Flagger.flag!(comment, 1, source.id, false)
    end
    assert Repo.get(Comment, comment.id).is_banned == true
    assert Repo.get!(User, target.id).reputation < target.reputation
  end
end
