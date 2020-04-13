defmodule CF.Moderation do
  @moduledoc """
  Collective moderation methods.
  A few concepts are necessary to understand what happens here:

  * An action can be flagged
  * When an action have a certain number of flags, it is considered as
    "reported". Collective moderation can then begins.
  * Depending on this moderation, updater will either revert the action
    or delete flags and restore the reported entity

  -------------

  Some usefull commands for testing:
  # Insert 5 comments with 10 flags on each
  DB.Factory.insert_list(5, :comment) |> Enum.map(&DB.Factory.with_action/1) |> CF.TestUtils.flag_comments(10)
  # Update flags
  CF.Jobs.Flags.update()
  """
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.ModerationUserFeedback
  alias DB.Schema.UserAction
  alias DB.Schema.Flag
  alias DB.Schema.Comment

  alias CF.Moderation.ModerationEntry
  alias CF.Accounts.UserPermissions

  @nb_flags_to_report %{
    {:create, :comment} => 1
  }

  @doc """
  Get the number of flags necessary for action to be considered as "reported"

  ## Examples

    iex> CF.Moderation.nb_flags_to_report(:create, :comment)
    1
  """
  @spec nb_flags_to_report(atom(), atom()) :: integer()
  def nb_flags_to_report(action, entity) when is_atom(action) and is_atom(entity),
    do: Map.get(@nb_flags_to_report, {action, entity})

  @doc """
  Get a random action for which number of flags is above the limit and for which
  user hasn't voted yet. Will raise if `user` doesn't have permission
  to moderate.
  """
  def random!(user) do
    UserPermissions.check!(user, :collective_moderation)

    UserAction
    |> where([a], a.user_id != ^user.id)
    |> without_user_feedback(user)
    |> join(:inner, [a, _], f in Flag, f.action_id == a.id)
    |> group_by([a, _, _], a.id)
    |> being_reported()
    |> preload([a, _, _], [:user])
    |> order_by(fragment("RANDOM()"))
    |> select([a, _, _], a)
    |> limit(1)
    |> Repo.one()
    |> moderation_entry()
  end

  @doc """
  Record user feedback for a flagged action
  Will raise if `user` doesn't have permission to moderate
  """
  def feedback!(user, action_id, value, flag_reason) do
    UserPermissions.check!(user, :collective_moderation)

    action =
      UserAction
      |> without_user_feedback(user)
      |> where([a, _], a.id == ^action_id)
      |> join(:inner, [a, _], f in Flag, f.action_id == a.id)
      |> group_by([a, _, _], a.id)
      # Following conditions will fail if target action is not reported. This is on purpose
      |> being_reported()
      |> Repo.one!()

    # Will fail if there's already a feedback for this user / action
    %ModerationUserFeedback{user_id: user.id, action_id: action.id}
    |> ModerationUserFeedback.changeset(%{value: value, flag_reason: flag_reason})
    |> Repo.insert()
  end

  @doc """
  Ban the given comment by setting the `is_reported` flag to `true`.
  In case of success, this function returns an :ok tuple with the updated comment.
  It can fail if comment doesn't exist anymore or if it is already banned.
  """
  @spec ban_comment(Comment.t()) :: {:ok, Comment.t()} | {:error, binary()}
  def ban_comment(comment_id) do
    Comment
    |> where([c], c.id == ^comment_id)
    |> where([c], c.is_reported == false)
    |> Repo.update_all([set: [is_reported: true]], returning: true)
    |> case do
      {1, [comment]} ->
        {:ok, comment}

      {0, _} ->
        {:error, "Comment doesn't exist or is already banned"}
    end
  end

  # ---- Private -----

  defp without_user_feedback(query, user) do
    query
    |> join(:left, [a], fb in subquery(user_feedbacks(user)), fb.action_id == a.id)
    |> where([_, fb], is_nil(fb.action_id))
  end

  defp user_feedbacks(%{id: user_id}) do
    where(ModerationUserFeedback, [f], f.user_id == ^user_id)
  end

  defp being_reported(base_query) do
    Enum.reduce(@nb_flags_to_report, base_query, fn {{action_type, entity}, nb_flags_to_report},
                                                    query ->
      having(
        query,
        [a, _, f],
        a.type == ^action_type and a.entity == ^entity and count(f.id) >= ^nb_flags_to_report
      )
    end)
  end

  defp moderation_entry(action = %UserAction{}) do
    %ModerationEntry{
      action: action,
      flags:
        Repo.all(
          from(
            f in Flag,
            where: f.action_id == ^action.id,
            preload: [:source_user]
          )
        )
    }
  end

  defp moderation_entry(nil) do
    nil
  end
end
