defmodule CaptainFact.Moderation do
  @moduledoc"""
  Collective moderation methods. A few concepts are necessary to understand what happens here:

  * An action can be flagged
  * When an action have a certain number of flags, it is considered as "reported". Collective moderation begins
  * Depending on this moderation, updater will either revert the action or delete flags and restore the reported entity
  """
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Moderation.UserFeedback
  alias CaptainFact.Accounts.UserPermissions
  alias CaptainFact.Actions.{UserAction, Flag}


  @default_nb_flags_report 1
  @nb_flags_report %{
    {UserAction.type(:create), UserAction.entity(:comment)} => 2
  }
  @defined_actions Enum.map(Map.keys(@nb_flags_report), &Tuple.to_list/1)


  @doc"""
  Get the number of flags necessary for action to be considered as "reported"

  ## Examples

    iex> CaptainFact.Moderation.nb_flags_report(:create, :comment)
    2
    iex> CaptainFact.Moderation.nb_flags_report(:update, :statement)
    1
  """
  def nb_flags_report(action, entity) when is_atom(action) and is_atom(entity),
    do: nb_flags_report(UserAction.type(action), UserAction.entity(entity))
  def nb_flags_report(action, entity),
    do: Map.get(@nb_flags_report, {action, entity}, @default_nb_flags_report)

  @doc"""
  Get all actions for which number of flags is above the limit in given `video_id` and for which user hasn't voted yet
  Will raise if `user` doesn't have permission to moderate
  """
  def video(user, video_id) do
    UserPermissions.check!(user, :collective_moderation)
    UserAction
    |> without_user_feedback(user)
    |> join(:inner, [a, _], f in Flag, f.action_id == a.id)
    |> where([a, _, _], a.context == ^UserAction.video_debate_context(video_id))
    |> group_by([a, _, _], a.id)
    |> having_default_reported()
    |> or_having_reported()
    |> preload([a, _, _], [:user])
    |> select([a, _, _], a)
    |> Repo.all()
    |> Enum.map(&load_changes/1)
    |> Enum.filter(&(&1 != nil))
  end

  @doc"""
  Get all actions for which number of flags is above the limit and for which user hasn't voted yet
  Will raise if `user` doesn't have permission to moderate
  """
  def random(user, nb_actions) do
    UserPermissions.check!(user, :collective_moderation)
    UserAction
    |> without_user_feedback(user)
    |> join(:inner, [a, _], f in Flag, f.action_id == a.id)
    |> group_by([a, _, _], a.id)
    |> having_default_reported()
    |> or_having_reported()
    |> preload([a, _, _], [:user])
    |> select([a, _, _], a)
    |> order_by(fragment("RANDOM()"))
    |> limit(^nb_actions)
    |> Repo.all()
    |> Enum.map(&load_changes/1)
    |> Enum.filter(&(&1 != nil))
  end

  @doc"""
  Record user feedback for a flagged action
  Will raise if `user` doesn't have permission to moderate
  """
  def feedback!(user, action_id, value) do
    UserPermissions.check!(user, :collective_moderation)

    action =
      UserAction
      |> without_user_feedback(user)
      |> where([a, _], a.id == ^action_id)
      |> join(:inner, [a, _], f in Flag, f.action_id == a.id)
      |> group_by([a, _, _], a.id)
      # Following conditions will fail if target action is not reported. This is on purpose
      |> having_default_reported()
      |> or_having_reported()
      |> Repo.one!()

    # Will fail if there's already a feedback for this user / action
    %UserFeedback{user_id: user.id, action_id: action.id}
    |> UserFeedback.changeset(%{value: value})
    |> Repo.insert!()

    # TODO record action
  end


  # ---- Private -----

  defp without_user_feedback(query, user) do
    query
    |> join(:left, [a], fb in subquery(user_feedbacks(user)), fb.action_id == a.id)
    |> where([_, fb], is_nil(fb.action_id))
  end

  defp user_feedbacks(%{id: user_id}) do
    where(UserFeedback, [f], f.user_id == ^user_id)
  end

  defp having_default_reported(query),
    do: having(query, [a, _, f], count(f.id) >= @default_nb_flags_report and not [a.type, a.entity] in @defined_actions)

  defp or_having_reported(base_query) do
    Enum.reduce(@nb_flags_report, base_query, fn {{action_type, entity}, nb_flags_report}, query ->
      or_having(query, [a, _, f], a.type == ^action_type and a.entity == ^entity and count(f.id) >= ^nb_flags_report)
    end)
  end

  @action_create UserAction.type(:create)
  @entity_comment UserAction.entity(:comment)
  defp load_changes(action = %{type: @action_create, entity: @entity_comment}) do
    # This ugly thing load data associated with comments creating actions, 1 query per action
    # It is acceptable as this is only used by a few priviledged users but in the future
    # we may want to store comments texts changes directly in :changes to avoid doing this
    CaptainFact.Comments.Comment
    |> where(id: ^action.entity_id)
    |> preload(:source)
    |> Repo.one()
    |> case do
         nil -> nil
         c ->
           changes = Map.take(c, [:text, :source]) |> Enum.filter(fn {_, value} -> value != nil end) |> Enum.into(%{})
           Map.put(action, :changes, changes)
       end
  end
  defp load_changes(action), do: action
end