defmodule CF.TestUtils do
  import DB.Factory
  import Ecto.Query
  import ExUnit.Assertions

  alias DB.Repo
  alias DB.Schema.Comment
  alias DB.Schema.UserAction

  def flag_comments(comments, nb_flags, reason \\ 1) do
    users = insert_list(nb_flags, :user, %{reputation: 1000})

    flags =
      Enum.map(comments, fn comment ->
        full_comment = Repo.preload(comment, :statement)

        Enum.map(users, fn user ->
          CF.Moderation.Flagger.flag!(
            user.id,
            full_comment.statement.video_id,
            full_comment,
            reason
          )
        end)
      end)

    List.flatten(flags)
  end

  def assert_deleted(%Comment{id: id}, check_actions \\ true) do
    {comment, actions} = get_comment_and_actions(id)
    assert is_nil(comment)

    if check_actions do
      assert Enum.count(actions) == 0
    end
  end

  def refute_deleted(%Comment{id: id}) do
    {comment, _} = get_comment_and_actions(id)
    assert comment != nil

    assert Repo.get_by(
             UserAction,
             entity: :comment,
             type: :delete,
             comment_id: id
           ) == nil
  end

  defp get_comment_and_actions(id) do
    actions =
      UserAction
      |> where([a], a.entity == ^:comment and a.comment_id == ^id)
      |> Repo.all()

    {Repo.get(Comment, id), actions}
  end
end
