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

  def is_iframe_allowed(_root, %{url: url}, _info) do
    case HTTPoison.head(url) do
      {:ok, %HTTPoison.Response{status_code: 200, headers: headers}} ->
        headers
        |> Enum.into(%{})
        |> Map.get("X-Frame-Options")
        |> case do
          nil ->
            {:ok, true}

          value ->
            case String.match?(value, ~r/deny|sameorigin/i) do
              true -> {:ok, false}
              false -> {:ok, true}
            end

          _ ->
            {:ok, false}
        end

      _ ->
        {:ok, false}
    end
  end
end
