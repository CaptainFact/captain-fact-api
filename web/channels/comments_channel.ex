defmodule CaptainFact.CommentsChannel do
  use CaptainFact.Web, :channel

  alias CaptainFact.{ Comment, CommentView, User, Statement, Vote, VoteView }
  alias CaptainFact.{ VideoHashId, Source }


  def join("comments:video:" <> video_id_hash, _payload, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    video_id = VideoHashId.decode!(video_id_hash)
    socket = assign(socket, :video_id, video_id)
    # TODO Move this query in Comment model multiple subqueries
    # Get comments
    query =
      from c in Comment,
      join: s in Statement, on: c.statement_id == s.id,
      join: u in User, on: u.id == c.user_id,
      left_join: source in Source, on: c.source_id == source.id,
      left_join: v in fragment("
        SELECT sum(value) AS score, comment_id
        FROM   votes
        GROUP BY comment_id
      "), on: v.comment_id == c.id,
      where: s.video_id == ^video_id,
      select: %{
        id: c.id,
        approve: c.approve,
        source: source,
        statement_id: c.statement_id,
        text: c.text,
        inserted_at: c.inserted_at,
        updated_at: c.updated_at,
        score: v.score,
        user: %{id: u.id, name: u.name, username: u.username}
      }
    rendered_comments = CommentView.render("index.json", comments: Repo.all(query))

    # Get user votes
    user_votes = if user != nil do
      Vote
      |> Vote.user_votes(user)
      |> Vote.video_votes(%{id: video_id})
      |> select([:comment_id, :value])
      |> Repo.all()
    else
      []
    end
    rendered_votes = VoteView.render("my_votes.json", votes: user_votes)

    {:ok, %{comments: rendered_comments, my_votes: rendered_votes}, socket}
  end

  def handle_in(command, params, socket) do
    case Guardian.Phoenix.Socket.current_resource(socket) do
      nil -> {:reply, :error, socket}
      _ -> handle_in_authentified(command, params, socket)
    end
  end

  def handle_in_authentified("new_comment", params, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    user
    |> build_assoc(:comments)
    |> Comment.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, comment} ->
        full_comment =
          %Comment{comment | user: user}
          |> Map.put(:score, 1)
          |> Repo.preload(:source)
        broadcast!(socket, "comment_added", CommentView.render("comment.json", comment: full_comment))
        handle_in_authentified("vote", %{"comment_id" => comment.id, "value" => "1"}, socket)
        Task.async(fn() ->
          fetch_source_title_and_update_comment(full_comment, socket.topic)
        end)
        {:reply, :ok, socket}
      {:error, _error} ->
        {:reply, :error, socket}
    end
  end

  def handle_in_authentified("delete_comment", %{"id" => id}, socket) do
    current_user = Guardian.Phoenix.Socket.current_resource(socket)
    comment = Repo.get!(Comment, id)
    if current_user.id === comment.user_id do
      Repo.delete!(comment)
      broadcast!(socket, "comment_removed", %{id: id, statement_id: comment.statement_id})
      {:reply, :ok, socket}
    else
      {:reply, :error, socket} # Not authorized
    end
  end

  def handle_in_authentified("vote", params = %{"comment_id" => comment_id}, socket) do
    current_user = Guardian.Phoenix.Socket.current_resource(socket)
    base_vote = case Repo.get_by(Vote, user_id: current_user.id, comment_id: comment_id) do
      nil -> build_assoc(current_user, :votes)
      vote -> vote
    end
    changeset = Vote.changeset(base_vote, params)
    case Repo.insert_or_update(changeset) do
      {:ok, vote} ->
        CaptainFact.VoteDebouncer.add_vote(socket.topic, vote.comment_id)
        {:reply, :ok, socket}
      {:error, _} ->
        {:reply, :error, socket}
    end
  end

  def fetch_source_title_and_update_comment(comment = %Comment{source: source = %{title: nil, url: url}}, topic) do
    case OpenGraph.fetch(url) do
      {_, %OpenGraph{title: nil}} -> nil
      {:ok, %OpenGraph{title: title}} ->
        source =
          Source.changeset(source, %{title: HtmlEntities.decode(title)})
          |> Repo.update!()
        updated_comment = Map.put(comment, :source, source)
        CaptainFact.Endpoint.broadcast(
          topic, "update_comment",
          CommentView.render("comment.json", comment: updated_comment)
        )
      {_, _} -> nil
    end
  end

  def fetch_source_title_and_update_comment(_, _), do: nil
end
