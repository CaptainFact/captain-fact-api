defmodule CaptainFact.Comments do
  import Ecto.Query
  require Logger

  alias DB.Repo
  alias DB.Schema.Source
  alias DB.Schema.Comment
  alias DB.Schema.Vote
  alias DB.Schema.User
  alias DB.Schema.UserAction

  alias CaptainFact.Accounts.UserPermissions
  alias CaptainFact.Actions.ActionCreator
  alias CaptainFact.Sources

  # ---- Public API ----

  @doc """
  Returns all comments for given `video_id`
  """
  def video_comments(video_id) do
    Comment
    |> Comment.full()
    |> where([c, s], s.video_id == ^video_id)
    |> Repo.all()
  end

  def add_comment(user, video_id, params, source_url \\ nil, source_fetch_callback \\ nil) do
    # TODO [Security] What if reply_to_id refer to a comment that is on a different statement ?
    UserPermissions.check!(user, :create, :comment)
    source_url = source_url && Source.prepare_url(source_url)

    source =
      source_url &&
        (Repo.get_by(Source, url: source_url) || Source.changeset(%Source{}, %{url: source_url}))

    comment_changeset =
      user
      |> Ecto.build_assoc(:comments)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:source, source)
      |> Comment.changeset(params)

    full_comment =
      comment_changeset
      |> Repo.insert!()
      |> Map.put(:user, user)
      |> Repo.preload(:source)
      |> Map.put(:score, 0)

    # Record action
    Repo.insert(ActionCreator.action_create(user.id, video_id, full_comment, source_url))

    # If new source, fetch metadata
    unless is_nil(source) || !is_nil(Map.get(source, :id)),
      do: fetch_source_metadata_and_update_comment(full_comment, source_fetch_callback)

    full_comment
  end

  # Delete

  @doc """
  Delete a comment. Patern match will fail if `comment`'s owner is not `user`

  Returns delete action or nil if comment doesn't exist
  """
  def delete_comment(
        user = %{id: user_id},
        video_id,
        comment = %{user_id: user_id, is_reported: false}
      ) do
    UserPermissions.check!(user, :delete, :comment)

    if do_delete_comment(comment) != false,
      do: Repo.insert!(ActionCreator.action_delete(user_id, video_id, comment))
  end

  @doc """
  ⚠️ Admin-only function. Delete a comment as admin.

  Returns delete action or nil if comment doesn't exist
  """
  def admin_delete_comment(comment = %Comment{}, video_id \\ nil) do
    if do_delete_comment(comment) != false,
      do: Repo.insert!(ActionCreator.action_admin_delete(video_id, comment))
  end

  defp do_delete_comment(comment) do
    # Delete replies actions (replies deletion is handle by db)
    replies_ids = get_all_replies_ids(comment.id)

    # Delete comment
    case Repo.delete_all(from(c in Comment, where: c.id == ^comment.id)) do
      {0, nil} -> false
      {1, nil} -> delete_comments_actions([comment.id | replies_ids])
    end
  end

  defp delete_comments_actions(comments_ids) do
    # Delete all actions linked to this comment
    UserAction
    |> where([a], a.entity == ^:comment)
    |> where([a], a.comment_id in ^comments_ids)
    |> Repo.delete_all()
  end

  # Recursively get replies ids. We should probably use a recursive query here
  @max_deepness 30
  defp get_all_replies_ids(comment_id, deepness \\ 0)
  defp get_all_replies_ids(_, @max_deepness), do: []

  defp get_all_replies_ids(comment_id, deepness) do
    base_return = if deepness == 0, do: [], else: [comment_id]

    case Repo.all(from(c in Comment, where: c.reply_to_id == ^comment_id, select: c.id)) do
      [] ->
        base_return

      replies ->
        base_return ++ List.flatten(Enum.map(replies, &get_all_replies_ids(&1, deepness + 1)))
    end
  end

  # ---- Comments voting ----

  def vote(user, video_id, comment_id, 0),
    do: delete_vote(user, video_id, Repo.get!(Comment, comment_id))

  def vote(user, video_id, comment_id, value) do
    comment = Repo.get!(Comment, comment_id)
    vote_type = Vote.vote_type(user, comment, value)
    comment_type = Comment.type(comment)
    UserPermissions.check!(user, vote_type, comment_type)

    # Delete prev directly vote if any (without logging a delete action)
    prev_vote = Repo.get_by(Vote, user_id: user.id, comment_id: comment_id)
    if prev_vote, do: Repo.delete(prev_vote)

    # Record vote
    vote =
      user
      |> Ecto.build_assoc(:votes)
      |> Vote.changeset(%{comment_id: comment_id, value: value})
      |> Repo.insert!()

    # Insert action
    Repo.insert!(ActionCreator.action_vote(user.id, video_id, vote_type, comment))

    # Return vote
    vote
  end

  def delete_vote(user, video_id, comment = %Comment{}) do
    delete_vote(
      user,
      video_id,
      comment,
      Repo.get_by!(Vote, user_id: user.id, comment_id: comment.id)
    )
  end

  def delete_vote(
        user = %User{id: user_id},
        video_id,
        comment = %Comment{},
        vote = %Vote{user_id: user_id}
      ) do
    vote_type = reverse_vote_type(Vote.vote_type(user, comment, vote.value))
    comment_type = Comment.type(comment)
    UserPermissions.check!(user, vote_type, comment_type)
    Repo.delete(vote)

    # Record action
    action = ActionCreator.action_revert_vote(user.id, video_id, vote_type, comment)
    Repo.insert!(action)

    %Vote{comment_id: comment.id}
  end

  # ---- Private ----

  defp reverse_vote_type(:vote_up), do: :revert_vote_up
  defp reverse_vote_type(:vote_down), do: :revert_vote_down
  defp reverse_vote_type(:self_vote), do: :revert_self_vote

  defp fetch_source_metadata_and_update_comment(%Comment{source: nil}, _), do: nil

  defp fetch_source_metadata_and_update_comment(comment = %Comment{source: base_source}, callback) do
    Sources.update_source_metadata(base_source, fn updated_source ->
      callback.(Map.merge(comment, %{source: updated_source, source_id: updated_source.id}))
    end)
  end
end
