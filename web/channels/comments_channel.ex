defmodule CaptainFact.CommentsChannel do
  use CaptainFact.Web, :channel

  alias CaptainFact.Comment
  alias CaptainFact.CommentView
  alias CaptainFact.User
  alias CaptainFact.Statement
  alias CaptainFact.Vote
  alias CaptainFact.VoteView


  def join("comments:video:" <> video_id_str, _payload, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    video_id = String.to_integer(video_id_str)
    socket = assign(socket, :video_id, video_id)
    # TODO store public user in socket
    # TODO verify user has_access
    # TODO Move this query in Comment model multiple subqueries
    # Get comments
    query =
      from c in Comment,
      join: s in Statement, on: c.statement_id == s.id,
      join: u in User, on: u.id == c.user_id,
      left_join: v in fragment("
        SELECT sum(value) AS score, comment_id
        FROM   votes
        GROUP BY comment_id
      "), on: v.comment_id == c.id,
      where: s.video_id == ^video_id,
      select: %{
        id: c.id,
        approve: c.approve,
        source_url: c.source_url,
        source_title: c.source_title,
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

  def handle_in("new_comment", comment, socket) do
    # TODO Verify statement exists and user is allowed for it (is_private on video)
    # TODO Verify user is connected (persist user in state)
    user = Guardian.Phoenix.Socket.current_resource(socket)
    changeset = Comment.changeset(%Comment{user_id: user.id}, comment)

    # TODO Add a vote from user on its own comment (and set score to 1 by default)
    case Repo.insert(changeset) do
      {:ok, comment} ->
        full_comment = %Comment{comment | user: user}
        |> Map.put(:score, 0)
        broadcast!(socket, "comment_added", CommentView.render("comment.json", comment: full_comment))
        {:reply, :ok, socket}
      {:error, _error} ->
        {:reply, :error, socket}
    end
  end

  def handle_in("delete_comment", %{"id" => id}, socket) do
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

  def handle_in("vote", vote, socket) do
    current_user = Guardian.Phoenix.Socket.current_resource(socket)
    base_vote = case Repo.get_by(Vote, user_id: current_user.id, comment_id: vote["comment_id"]) do
      nil -> %Vote{user_id: current_user.id}
      vote -> vote
    end
    changeset = Vote.changeset(base_vote, vote)
    case Repo.insert_or_update(changeset) do
      {:ok, vote} ->
        CaptainFact.VoteDebouncer.add_vote(socket.topic, vote.comment_id)
        {:reply, :ok, socket}
      {:error, _} ->
        {:reply, :error, socket}
    end
  end
end
