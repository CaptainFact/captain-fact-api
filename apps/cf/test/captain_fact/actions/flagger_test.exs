defmodule CF.Actions.FlaggerTest do
  use CF.DataCase

  alias DB.Schema.User
  alias DB.Schema.Comment
  alias DB.Schema.Flag

  alias CF.Actions.Flagger
  alias CF.Jobs.{Flags, Reputation}
  alias CF.Moderation

  @nb_flags_to_report Moderation.nb_flags_to_report(:create, :comment)

  setup do
    Repo.delete_all(Flag)
    Repo.delete_all(User)
    target_user = insert(:user, %{reputation: 10_000})
    comment = insert(:comment, %{user: target_user}) |> with_action
    source_users = insert_list(@nb_flags_to_report, :user, %{reputation: 10_000})
    {:ok, [source_users: source_users, target_user: target_user, comment: comment]}
  end

  test "flags get inserted in DB", context do
    source = List.first(context[:source_users])
    comment = context[:comment]

    Flagger.flag!(source.id, comment.statement.video_id, comment, 1)
    Reputation.update()
    Flags.update()
    assert Flagger.get_nb_flags(comment) == 1
  end

  test "comment reported after x flags", context do
    comment = context[:comment]

    for source <- context[:source_users],
        do: Flagger.flag!(source.id, comment.statement.video_id, comment, 1)

    Reputation.update()
    Flags.update()
    assert Repo.get(Comment, comment.id).is_reported == true
  end
end
