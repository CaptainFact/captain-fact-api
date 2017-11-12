defmodule CaptainFact.Comments.CommentsChannel do
  use CaptainFactWeb, :channel

  import CaptainFactWeb.UserSocket, only: [handle_in_authenticated: 4]
  alias CaptainFactWeb.{ CommentView, VoteView }
  alias CaptainFact.Accounts.User
  alias CaptainFact.Videos.VideoHashId
  alias CaptainFact.Actions.{Flagger, UserAction, Flag}
  alias CaptainFact.Comments
  alias CaptainFact.Comments.{Comment, Vote}


  def join("comments:video:" <> video_id_hash, _payload, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    video_id = VideoHashId.decode!(video_id_hash)
    response =
      %{}
      |> Map.put(:comments, CommentView.render("index.json", comments:
          Comment.full(Comment)
          |> where([c, s], s.video_id == ^video_id)
          |> where([c, _], c.is_reported == false)
          |> Repo.all()
        ))
      |> load_user_data(user, video_id)

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
      comment = Repo.preload(comment, :source) |> Repo.preload(:user)
      rendered_comment = CommentView.render("comment.json", comment: comment)
      broadcast!(socket, "comment_updated", rendered_comment)
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
        broadcast!(socket, "comment_removed", %{
          id: id,
          statement_id: comment.statement_id,
          reply_to_id: comment.reply_to_id
        })
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
end
