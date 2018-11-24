defmodule CF.Comments do
  require Logger

  import Ecto.Query
  import CF.Actions.ActionCreator

  alias Ecto.Multi

  alias DB.Repo
  alias DB.Schema.Source
  alias DB.Schema.Comment
  alias DB.Schema.Vote
  alias DB.Schema.User
  alias DB.Schema.UserAction

  alias CF.Accounts.UserPermissions
  alias CF.Sources

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

    # Load source from DB or create a changeset to make a new one
    source =
      source_url &&
        (Sources.get_by_url(source_url) || Source.changeset(%Source{}, %{url: source_url}))

    # Insert comment in DB
    full_comment =
      user
      |> Ecto.build_assoc(:comments)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:source, source)
      |> Comment.changeset(params)
      |> Repo.insert!()
      |> Map.put(:user, user)
      |> Repo.preload(:source)
      |> Map.put(:score, 0)

    # Record action
    Repo.insert(action_create(user.id, video_id, full_comment, source_url))

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
      do: Repo.insert!(action_delete(user_id, video_id, comment))
  end

  @doc """
  ⚠️ Admin-only function. Delete a comment as admin.

  Returns delete action or nil if comment doesn't exist
  """
  def admin_delete_comment(comment = %Comment{}, video_id \\ nil) do
    if do_delete_comment(comment) != false,
      do: Repo.insert!(action_admin_delete(video_id, comment))
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

  @doc """
  Vote on given comment. Will delete vote if value is 0 or if comment does not
  exist.

  Returns a tuple like {:ok, vote, prev_value}
  """
  @spec vote!(User.t(), integer(), integer(), Vote.vote_value() | 0) ::
          {:ok, Comment.t(), Vote.t(), integer()} | {:error, any()}
  def vote!(user, video_id, comment_id, 0) do
    comment = Repo.get!(Comment, comment_id)

    case delete_vote!(user, video_id, comment) do
      {:ok, vote} ->
        {:ok, comment, %{vote | value: 0}, vote.value}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def vote!(user, video_id, comment_id, value) do
    comment = Repo.get!(Comment, comment_id)
    vote_type = Vote.vote_type(user, comment, value)
    comment_type = Comment.type(comment)
    UserPermissions.check!(user, vote_type, comment_type)

    # Delete prev directly vote if any (without logging a delete action)
    Multi.new()
    |> Multi.delete_all(:prev_vote, Vote.user_comment_vote(user, comment), returning: [:value])
    |> Multi.insert(:vote, Vote.changeset_new(user, comment, value))
    |> Multi.insert(:vote_action, action_vote(user.id, video_id, vote_type, comment))
    |> Repo.transaction()
    |> case do
      {:ok, %{vote: vote, prev_vote: {0, []}}} ->
        {:ok, comment, %{vote | comment_id: comment.id, comment: comment}, 0}

      {:ok, %{vote: vote, prev_vote: {_, [%{value: prev_value}]}}} ->
        {:ok, comment, %{vote | comment_id: comment.id, comment: comment}, prev_value}

      {:error, _, reason, _} ->
        {:error, reason}
    end
  end

  @doc """
  Delete user vote. Will raise if user does not have permission.
  """
  @spec delete_vote!(User.t(), integer(), Comment.t()) :: {:ok, Vote.t()} | {:error, any()}
  def delete_vote!(user, video_id, comment = %Comment{}) do
    case Repo.get_by(Vote, user_id: user.id, comment_id: comment.id) do
      nil ->
        {:error, "User has no vote for this comment"}

      vote ->
        delete_vote!(user, video_id, comment, vote)
    end
  end

  @spec delete_vote!(User.t(), integer(), Comment.t(), Vote.t()) ::
          {:ok, Vote.t()} | {:error, any()}
  def delete_vote!(
        user = %User{id: user_id},
        video_id,
        comment = %Comment{},
        vote = %Vote{user_id: user_id}
      ) do
    vote_type = reverse_vote_type(Vote.vote_type(user, comment, vote.value))
    comment_type = Comment.type(comment)
    UserPermissions.check!(user, vote_type, comment_type)

    Multi.new()
    |> Multi.delete_all(:delete_existing, Vote.user_comment_vote(user, comment))
    |> Multi.insert(:delete_action, action_revert_vote(user.id, video_id, vote_type, comment))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, vote}

      {:error, _, reason, _} ->
        {:error, reason}
    end
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
