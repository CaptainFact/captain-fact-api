defmodule CaptainFactGraphql.Resolvers.Comments do
  import Absinthe.Resolution.Helpers, only: [batch: 3]
  import Ecto.Query
  alias CaptainFact.Comments.Vote
  alias CaptainFact.Repo


  def score(comment, _args, _info) do
    batch({__MODULE__, :comments_scores}, comment.id, fn results ->
      {:ok, Map.get(results, comment.id) || 0}
    end)
  end

  def comments_scores(_, comments_ids) do
    from(
      v in Vote,
      where: v.comment_id in ^comments_ids,
      select: {v.comment_id, sum(v.value)},
      group_by: v.comment_id
    )
    |> Repo.all()
    |> Enum.into(%{})
  end
end