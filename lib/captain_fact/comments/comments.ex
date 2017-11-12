defmodule CaptainFact.Comments do
  import Ecto.{Query}
  require Logger

  alias CaptainFact.Repo
  alias CaptainFact.Comments.{Comment, Vote}
  alias CaptainFact.Accounts.{UserPermissions, User}
  alias CaptainFact.Sources.{Fetcher, Source}
  alias CaptainFact.Actions.{Recorder, UserAction}


  # ---- Public API ----

  def add_comment(user, context, params, source_url, source_fetch_callback \\ nil) do
    # TODO [Security] What if reply_to_id refer to a comment that is on a different statement ?
    UserPermissions.check!(user, :create, :comment)
    source = source_url && (Repo.get_by(Source, url: source_url) || %{url: source_url})
    comment_changeset =
      user
      |> Ecto.build_assoc(:comments)
      |> Ecto.Changeset.change(%{})
      |> Ecto.Changeset.put_assoc(:source, source)
      |> Comment.changeset(params)

    full_comment =
      Repo.insert!(comment_changeset)
      |> Map.put(:user, user)
      |> Repo.preload(:source)
      |> Map.put(:score, 1)

    # Record action
    Recorder.record!(user, :create, :comment, action_params(context, full_comment))

    # Self vote
    Task.start(fn() -> vote(user, context, full_comment.id, 1) end)

    # If new source, fetch metadata
    unless is_nil(source) || Map.get(source, :id),
      do: fetch_source_metadata_and_update_comment(full_comment, source_fetch_callback)
    full_comment
  end

  # Delete

  @doc"""
  ⚠️ Admin-only function. Delete a comment as admin.

  Returns delete action or nil if comment doesn't exist
  """
  def delete_comment(user = %{id: user_id}, comment = %{user_id: user_id, is_reported: false}, context \\ nil) do
    UserPermissions.check!(user, :delete, :comment)
    if do_delete_comment(comment) != false,
      do: Recorder.record!(user, :delete, :comment, %{entity_id: comment.id, context: context})
  end

  @doc"""
  ⚠️ Admin-only function. Delete a comment as admin.

  Returns delete action or nil if comment doesn't exist
  """
  def admin_delete_comment(comment_id, context \\ nil)
  def admin_delete_comment(comment_id, context) when is_integer(comment_id),
    do: admin_delete_comment(%Comment{id: comment_id}, context)
  def admin_delete_comment(comment = %Comment{}, context) do
    if do_delete_comment(comment) != false,
      do: Recorder.admin_record!(:delete, :comment, %{entity_id: comment.id, context: context})
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
    |> where([a], a.entity == ^UserAction.entity(:comment))
    |> where([a], a.entity_id in ^comments_ids)
    |> Repo.delete_all()
  end

  # Recursively get replies ids. We should probably use a recursive query here
  @max_deepness 30
  defp get_all_replies_ids(comment_id, deepness \\ 0)
  defp get_all_replies_ids(_, @max_deepness), do: []
  defp get_all_replies_ids(comment_id, deepness) do
    base_return = if deepness == 0, do: [], else: [comment_id]
    case Repo.all(from(c in Comment, where: c.reply_to_id == ^comment_id, select: c.id)) do
      [] -> base_return
      replies -> base_return ++ List.flatten(Enum.map(replies, &(get_all_replies_ids(&1, deepness + 1))))
    end
  end

  # ---- Comments voting ----

  def vote(user, context, comment_id, 0),
    do: delete_vote(user, context, Repo.get!(Comment, comment_id))
  def vote(user, context, comment_id, value) do
    comment = Repo.get!(Comment, comment_id)
    vote_type = Vote.vote_type(user, comment, value)
    comment_type = comment_type(comment)
    UserPermissions.check!(user, vote_type, comment_type)

    # Delete prev vote if any
    prev_vote = Repo.get_by(Vote, user_id: user.id, comment_id: comment_id)
    if prev_vote, do: delete_vote(user, context, comment, prev_vote)

    # Record vote
    return =
      Ecto.build_assoc(user, :votes)
      |> Vote.changeset(%{comment_id: comment_id, value: value})
      |> Repo.insert!()
    Recorder.record!(user, vote_type, comment_type, action_params(context, comment))
    return
  end

  def delete_vote(user, context, comment = %Comment{}),
    do: delete_vote(user, context, comment, Repo.get_by!(Vote, user_id: user.id, comment_id: comment.id))
  def delete_vote(user = %User{id: user_id}, context, comment = %Comment{}, vote = %Vote{user_id: user_id}) do
    vote_type = reverse_vote_type(Vote.vote_type(user, comment, vote.value))
    comment_type = comment_type(comment)
    UserPermissions.check!(user, vote_type, comment_type)
    Repo.delete(vote)
    Recorder.record!(user, vote_type, comment_type, action_params(context, comment))
    %Vote{comment_id: comment.id}
  end

  def comment_type(%Comment{source_id: nil}), do: :comment
  def comment_type(%Comment{}), do: :fact

  # ---- Private ----

  defp action_params(context, comment), do: %{context: context, target_user_id: comment.user_id, entity_id: comment.id}

  defp reverse_vote_type(:vote_up), do: :revert_vote_up
  defp reverse_vote_type(:vote_down), do: :revert_vote_down
  defp reverse_vote_type(:self_vote), do: :revert_self_vote

  defp fetch_source_metadata_and_update_comment(%Comment{source: nil}, _), do: nil
  defp fetch_source_metadata_and_update_comment(comment = %Comment{source: base_source}, callback) do
    Fetcher.fetch_source_metadata(base_source.url, fn
      metadata when metadata == %{} -> nil
      metadata ->
        og_url = Map.get(metadata, :url)
        updated_source =
          # Check if we got a new url from metadata
          if og_url && og_url != base_source.url do
            case Repo.transaction(fn ->
              # Get real source (or create it)
              real_source = case Repo.get_by(Source, url: og_url) do
                nil -> Repo.insert!(Source.changeset(%Source{}, metadata))
                source -> Repo.update!(Source.changeset(source, metadata))
              end
              # Update all references to prev source
              Comment
              |> where([c], c.source_id == ^base_source.id)
              |> Repo.update_all(set: [source_id: real_source.id])

              # Delete original source
              Repo.delete!(base_source)

              real_source # Return updated source
            end) do
              {:ok, real_source} ->
                real_source
              {:error, _} ->
                Logger.error("Source update for #{base_source.url} with new url #{og_url} failed")
            end
          else
            # Otherwise just update source with new metadata
            Repo.update!(Source.changeset(base_source, metadata))
          end

        # TODO Comment may have been edited. Reload from DB
        if updated_source && callback, do: callback.(Map.put(comment, :source, updated_source))
    end)
  end
end