defmodule CF.Graphql.Resolvers.Comments do
  import Absinthe.Resolution.Helpers, only: [batch: 3]
  import Ecto.Query
  alias DB.Repo
  alias DB.Schema.Vote

  def score(comment, _args, _info) do
    batch({__MODULE__, :comments_scores}, comment.id, fn results ->
      {:ok, Map.get(results, comment.id) || 0}
    end)
  end

  def comments_scores(_, comments_ids) do
    Vote
    |> where([v], v.comment_id in ^comments_ids)
    |> select([v], {v.comment_id, sum(v.value)})
    |> group_by([v], v.comment_id)
    |> Repo.all()
    |> Enum.into(%{})
  end
end
