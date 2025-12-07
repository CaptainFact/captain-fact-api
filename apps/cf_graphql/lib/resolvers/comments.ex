defmodule CF.Graphql.Resolvers.Comments do
  import Absinthe.Resolution.Helpers, only: [batch: 3]
  import Ecto.Query
  alias DB.Repo
  alias DB.Schema.Vote
  alias DB.Schema.Comment
  alias DB.Schema.Statement
  alias CF.Comments
  alias CF.Graphql.Subscriptions

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

  # Mutations

  def create(_root, args = %{statement_id: statement_id}, %{context: %{user: user}}) do
    # Get statement to find video_id
    statement = Repo.get!(Statement, statement_id)
    video_id = statement.video_id
    reply_to_id = Map.get(args, :reply_to_id)

    params = %{
      "statement_id" => statement_id,
      "text" => Map.get(args, :text),
      "reply_to_id" => reply_to_id,
      "approve" => Map.get(args, :approve)
    }

    source_url = Map.get(args, :source)

    # Comments.add_comment returns the comment directly or {:error, reason}
    case Comments.add_comment(user, video_id, params, source_url) do
      {:error, reason} ->
        {:error, reason}

      comment ->
        # Preload associations for GraphQL response
        comment = Repo.preload(comment, [:source, :user, :statement])

        Subscriptions.publish_comment_added(comment, video_id)
        {:ok, comment}
    end
  end

  def delete(_root, %{id: id}, %{context: %{user: user}}) do
    comment = Repo.get!(Comment, id) |> Repo.preload(:statement)
    video_id = comment.statement.video_id

    case Comments.delete_comment(user, video_id, comment) do
      nil ->
        {:ok, %{id: id, statement_id: comment.statement_id, reply_to_id: comment.reply_to_id}}

      _ ->
        Subscriptions.publish_comment_removed(comment, video_id)
        {:ok, %{id: id, statement_id: comment.statement_id, reply_to_id: comment.reply_to_id}}
    end
  end

  def vote(_root, %{comment_id: comment_id, value: value}, %{context: %{user: user}}) do
    # Get comment and preload statement to access video_id
    comment = Repo.get!(Comment, comment_id) |> Repo.preload(:statement)
    video_id = comment.statement.video_id

    case Comments.vote!(user, video_id, comment_id, value) do
      {:ok, comment, vote, prev_value} ->
        # Calculate score diff (same logic as comments_channel.ex)
        diff = value_diff(prev_value, vote.value)

        # Publish score diff via subscription
        Subscriptions.publish_comment_score_diff(comment, diff, video_id)

        # Preload associations for GraphQL response
        comment = Repo.preload(comment, [:source, :user, :statement])
        {:ok, comment}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper function to calculate vote value diff (matches comments_channel.ex logic)
  defp value_diff(0, new_value), do: new_value
  defp value_diff(prev_value, new_value), do: new_value - prev_value
end
