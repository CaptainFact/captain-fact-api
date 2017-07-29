defmodule CaptainFactWeb.CommentsChannel do
  use CaptainFactWeb, :channel

  import CaptainFactWeb.UserSocket, only: [handle_in_authenticated: 4]
  alias CaptainFact.Accounts.User
  alias CaptainFactWeb.{ Comment, CommentView, Vote, VoteView, Flag, Source }
  alias CaptainFact.{ VideoHashId, VoteDebouncer, Flagger }
  alias CaptainFact.Accounts.{ReputationUpdater, UserPermissions}


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
    # TODO [Security] What if reply_to_id refer to a comment that is on a different statement ?
    user = Repo.get!(User, socket.assigns.user_id)
    comment = UserPermissions.lock!(user, :add_comment, fn user ->
      user
      |> build_assoc(:comments)
      |> Comment.changeset(params)
      |> Repo.insert!()
    end)
    full_comment = comment |> Map.put(:user, user) |> Repo.preload(:source) |> Map.put(:score, 1)
    broadcast!(socket, "comment_added", CommentView.render("comment.json", comment: full_comment))
    handle_in_authenticated!("vote", %{"comment_id" => full_comment.id, "value" => "1"}, socket)
    Task.async(fn() ->
      fetch_source_metadata_and_update_comment(full_comment, socket.topic)
    end)
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

  def handle_in_authenticated!("vote", params = %{"comment_id" => comment_id}, socket) do
    comment =
      Comment.with_source(Comment, false)
      |> where(id: ^comment_id)
      |> select([:user_id])
      |> Repo.one!()
    action = cond do
      socket.assigns.user_id == comment.user_id -> :self_vote
      (params["value"] || Map.get(params, :value)) >= 0 -> :vote_up
      true -> :vote_down
    end
    {base_vote, new_vote} = UserPermissions.lock!(socket.assigns.user_id, action, fn user ->
      base_vote = Repo.get_by(Vote, user_id: user.id, comment_id: comment_id) || %Vote{user_id: user.id}
      new_vote = Repo.insert_or_update!(Vote.changeset(base_vote, params))
      {base_vote, new_vote}
    end)
    VoteDebouncer.add_vote(socket.topic, new_vote.comment_id)
    with true <- action != :self_vote,
         vote_type when not is_nil(vote_type) <- Vote.get_vote_type(comment, base_vote.value, new_vote.value) do
      ReputationUpdater.register_action(socket.assigns.user_id, comment.user_id, vote_type)
    end
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

  # Metadata fetching

  defp fetch_source_metadata_and_update_comment(comment = %Comment{source: source = %{title: nil, url: url}}, topic) do
    case fetch_source_metadata(url) do
      {:error, _} -> nil
      {:ok, source_params} when source_params == %{} -> nil
      {:ok, source_params} ->
        source_params = if source_params.url == url,
          do: Map.delete(source_params, :url),
          else: source_params
        # TODO Check if this url already exists. If it does, merge it and remove this source
        updated_source = Repo.update!(Source.changeset(source, source_params))
        # TODO Comment may have been edited. Reload from DB
        updated_comment = Map.put(comment, :source, updated_source)
        rendered_comment = CommentView.render("comment.json", comment: updated_comment)
        CaptainFactWeb.Endpoint.broadcast(topic, "comment_updated", rendered_comment)
    end
  end

  defp fetch_source_metadata_and_update_comment(_, _), do: nil

  defp fetch_source_metadata(url) do
    case HTTPoison.get(url, [], [follow_redirect: true, max_redirect: 5]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        tree = Floki.parse(body)
        source_params =
          %{
            title: Floki.attribute(tree, "meta[property='og:title']", "content"),
            language: Floki.attribute(tree, "html", "lang"),
            site_name: Floki.attribute(tree, "meta[property='og:site_name']", "content"),
            url: Floki.attribute(tree, "meta[property='og:url']", "content")
          }
          |> Enum.map(fn({key, value}) -> {key, List.first(value)} end)
          |> Enum.filter(fn({_key, value}) -> value != nil end)
          |> Enum.map(fn(entry = {key, value}) ->
            if key in [:title, :site_name],
              do: {key, HtmlEntities.decode(value)},
              else: entry
            end)
          |> Enum.into(%{})
        {:ok, source_params}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Not found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
      end
  end
end
