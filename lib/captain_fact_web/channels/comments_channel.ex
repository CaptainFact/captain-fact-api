defmodule CaptainFact.Comments.CommentsChannel do
  use CaptainFactWeb, :channel

  import CaptainFactWeb.UserSocket, only: [handle_in_authenticated: 4]
  alias CaptainFact.Accounts.User
  alias CaptainFactWeb.{ CommentView, VoteView, Flag }
  alias CaptainFact.{ VideoHashId, Flagger }
  alias CaptainFact.Comments
  alias CaptainFact.Comments.{Comment, Vote, VoteDebouncer}


  def join("comments:video:" <> video_id_hash, _payload, socket) do
    user = Guardian.Phoenix.Socket.current_resource(socket)
    video_id = VideoHashId.decode!(video_id_hash)
    response =
      %{}
      |> Map.put(:comments, CommentView.render("index.json", comments:
          Comment.full(Comment)
          |> where([c, s], s.video_id == ^video_id)
          |> where([c, _], c.is_banned == false)
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
    comment = Comments.add_comment(user, params, source_url, fn comment ->
      comment = Repo.preload(comment, :source) |> Repo.preload(:user)
      rendered_comment = CommentView.render("comment.json", comment: comment)
      broadcast!(socket, "comment_updated", rendered_comment)
    end)
    broadcast!(socket, "comment_added", CommentView.render("comment.json", comment: comment))
    {:reply, :ok, socket}
  end

  def handle_in_authenticated!("delete_comment", %{"id" => id}, socket) do
    comment = Repo.get!(Comment, id)
    if socket.assigns.user_id === comment.user_id do
      Repo.delete!(comment)
      broadcast!(socket, "comment_removed", %{
        id: id,
        statement_id: comment.statement_id,
        reply_to_id: comment.reply_to_id
      })
      {:reply, :ok, socket}
    else
      {:reply, :error, socket} # Not authorized
    end
  end

  def handle_in_authenticated!("vote", %{"comment_id" => comment_id, "value" => value}, socket) do
    vote = Comments.vote(Repo.get(User, socket.assigns.user_id), comment_id, value)
    VoteDebouncer.add_vote(socket.topic, vote.comment_id)
    {:reply, :ok, socket}
  end

  def handle_in_authenticated!("flag_comment", %{"id" => comment_id, "reason" => reason}, socket) do
    try do
      Comment
      |> select([:id, :user_id])
      |> preload([:user])
      |> where(id: ^comment_id)
      |> where(is_banned: false)
      |> Repo.one!()
      |> Flagger.flag!(reason, socket.assigns.user_id)
      {:reply, :ok, socket}
    rescue e in Ecto.ConstraintError ->
      # TODO migrate to user_socket rescue_channel_errors with other constraints violations
      if e.constraint == "flags_source_user_id_type_entity_id_index" do
        {:reply, {:error, %{message: "action_already_done"}}, socket}
      else
        throw e
      end
    end
  end

  defp load_user_data(response, nil, _), do: response
  defp load_user_data(response = %{comments: comments}, user = %User{}, video_id) do
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
        |> where([f], f.type == 1) #TODO Use method
        |> where([f], f.entity_id in ^comments_ids)
        |> select([:entity_id])
        |> Repo.all()
        |> Enum.map(&(&1.entity_id))
      )
  end
end
