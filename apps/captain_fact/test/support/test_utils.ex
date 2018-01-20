defmodule CaptainFact.TestUtils do
  import CaptainFact.Factory
  import Ecto.Query
  import ExUnit.Assertions

  alias DB.Repo
  alias CaptainFact.Comments.Comment
  alias CaptainFact.Actions.UserAction


  def flag_comments(comments, nb_flags, reason \\ 1) do
    users = insert_list(nb_flags, :user, %{reputation: 1000})
    Enum.map(comments, fn comment ->
      Enum.map(users, fn user ->
        CaptainFact.Actions.Flagger.flag!(user.id, comment, reason)
      end)
    end) |> List.flatten()
  end

  def assert_deleted(%Comment{id: id}, check_actions \\ true) do
    {comment, actions} = get_comment_and_actions(id)
    assert is_nil(comment)
    if check_actions do
      assert Enum.count(actions) == 1
      assert hd(actions).type == UserAction.type(:delete)
    end
  end

  def refute_deleted(%Comment{id: id}) do
    {comment, _} = get_comment_and_actions(id)
    assert comment != nil
    assert Repo.get_by(UserAction, entity: UserAction.entity(:comment), type: UserAction.type(:delete), entity_id: id) == nil
  end

  defp get_comment_and_actions(id) do
    actions =
      UserAction
      |> where([a], a.entity == ^UserAction.entity(:comment) and a.entity_id == ^id)
      |> Repo.all()

    {Repo.get(Comment, id), actions}
  end
end