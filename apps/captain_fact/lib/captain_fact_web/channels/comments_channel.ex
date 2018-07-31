defmodule CaptainFactWeb.CommentsChannel do
  use CaptainFactWeb, :channel

  import CaptainFactWeb.UserSocket, only: [handle_in_authenticated: 4]
  alias CaptainFactWeb.{CommentView, VoteView}
  alias CaptainFactWeb.Endpoint

  alias DB.Type.VideoHashId
  alias DB.Schema.User
  alias DB.Schema.UserAction
  alias DB.Schema.Flag
  alias DB.Schema.Comment
  alias DB.Schema.Vote

  alias CaptainFact.Actions.Flagger
  alias CaptainFact.Comments


  @event_comment_updated "comment_updated"
  @event_comment_removed "comment_removed"

  # ---- Public API (called from external code) ----

  @doc"""
  Broadcast a comment update on concerned channels.
  Fetch `video_id` and `statement_id` from DB.
  """
  def broadcast_comment_update(comment_id, updated_fields) do
    Comment
    |> preload(:statement)
    |> where([c], c.id == ^comment_id)
    |> Repo.one()
    |> case do
         nil ->
           {:error, :not_found}
         comment ->
           channel = comments_channel(comment.statement.video_id)
           msg = msg_partial_update(comment, updated_fields)
           Endpoint.broadcast(channel, @event_comment_updated, msg)
       end
  end

  @doc"""
  Broadcast a comment remove on concerned channels.
  """
  def broadcast_comment_remove(comment = %Comment{}) do
    comment.statement.video_id
    |> comments_channel()
    |> Endpoint.broadcast(@event_comment_removed, msg_comment_remove(comment))
  end

  defp comments_channel(video_id) when is_integer(video_id) do
    "comments:video:#{VideoHashId.encode(video_id)}"
  end

  # ---- Channel API ----

  def join("comments:video:" <> video_id_hash, _payload, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    video_id = VideoHashId.decode!(video_id_hash)
    comments = Comments.video_comments(video_id)
    rendered_comments = CommentView.render("index.json", comments: comments)
    response = load_user_data(%{comments: rendered_comments}, user, video_id)
    socket = assign(socket, :video_id, video_id)
    
    {:ok, response, socket}
  end

  def handle_in(command, params, socket) do
    handle_in_authenticated(command, params, socket, &handle_in_authenticated!/3)
  end

  def handle_in_authenticated!("new_comment", params, socket) do
    source_url = get_in(params, ["source", "url"])
    user = Repo.get!(User, socket.assigns.user_id)
    comment = Comments.add_comment(user, context(socket), params, source_url, fn comment ->
      comment = Repo.preload(Repo.preload(comment, :source), :user)
      rendered_comment = CommentView.render("comment.json", comment: comment)
      broadcast!(socket, @event_comment_updated, rendered_comment)
    end)
    broadcast!(socket, "comment_added", CommentView.render("comment.json", comment: comment))
    {:reply, :ok, socket}
  end

  def handle_in_authenticated!("delete_comment", %{"id" => id}, socket) do
    comment = Repo.get!(Comment, id)
    user = Repo.get!(User, socket.assigns.user_id)
    case Comments.delete_comment(user, comment, context(socket)) do
      nil -> {:reply, :ok, socket}
      _ ->
        broadcast!(socket, @event_comment_removed, msg_comment_remove(comment))
        {:reply, :ok, socket}
    end
  end

  def handle_in_authenticated!("vote", %{"comment_id" => comment_id, "value" => value}, socket) do
    Comments.vote(Repo.get!(User, socket.assigns.user_id), context(socket), comment_id, value)
    {:reply, :ok, socket}
  end

  def handle_in_authenticated!("flag_comment", %{"id" => comment_id, "reason" => reason}, socket) do
    Flagger.flag!(socket.assigns.user_id, comment_id, reason)
    {:reply, :ok, socket}
  end

  defp context(socket), do: UserAction.video_debate_context(socket.assigns.video_id)

  defp load_user_data(response, nil, _), do: response
  defp load_user_data(response = %{comments: comments}, user = %User{}, video_id) do
    # TODO move these queries to Flagger
    comments_ids = Enum.map(comments, &(&1.id))
    response
    |> Map.put(:my_votes, VoteView.render("my_votes.json", votes:
        Vote
        |> Vote.user_votes(user)
        |> Vote.video_votes(%{id: video_id})
        |> select([:comment_id, :value])
        |> Repo.all()
      ))
    |> Map.put(:my_flags,
        Flag
        |> where([f], f.source_user_id == ^user.id)
        |> join(:inner, [f], a in assoc(f, :action))
        |> where([_, a], a.entity == ^UserAction.entity(:comment))
        |> where([_, a], a.entity_id in ^comments_ids)
        |> select([_, a], a.entity_id)
        |> Repo.all()
      )
  end

  # ---- Messages builders ----

  defp msg_comment_remove(comment = %Comment{}) do
    %{
      id: comment.id,
      statement_id: comment.statement_id,
      reply_to_id: comment.reply_to_id
    }
  end

  defp msg_partial_update(comment = %Comment{}, updated_fields) do
    Map.merge(%{
      id: comment.id,
      statement_id: comment.statement_id,
      reply_to_id: comment.reply_to_id,
      __partial: true
    }, Map.take(comment, updated_fields))
  end
end
