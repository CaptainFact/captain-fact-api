defmodule CaptainFact.Moderation do
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Actions.{UserAction, Flag} # TODO move flag module here


  @default_nb_flags_to_ban 3
  @nb_flags_to_ban %{
    {UserAction.type(:create), UserAction.entity(:comment)} => 5
  }
  @defined_actions Enum.map(Map.keys(@nb_flags_to_ban), &Tuple.to_list/1)


  @doc"""
  Get the number of flags necessary to ban action.

  ## Examples

    iex> CaptainFact.Moderation.nb_flags_to_ban(:create, :comment)
    5
    iex> CaptainFact.Moderation.nb_flags_to_ban(:update, :statement)
    3
  """
  def nb_flags_to_ban(action, entity) when is_atom(action) and is_atom(entity),
    do: nb_flags_to_ban(UserAction.type(action), UserAction.entity(entity))
  def nb_flags_to_ban(action, entity),
    do: Map.get(@nb_flags_to_ban, {action, entity}, @default_nb_flags_to_ban)

  @doc"""
  Get all actions for which number of flags is above the limit in given `video_id`
  """
  def video(video_id) do
    UserAction
    |> join(:inner, [a], f in Flag, f.action_id == a.id)
    |> where([a, _], a.context == ^UserAction.video_debate_context(video_id))
    |> group_by([a, _], a.id)
    |> having_default_ban()
    |> or_having_ban_defined()
    |> preload([a, _], [:user])
    |> select([a, _], a)
    |> Repo.all()
    |> Enum.map(&load_changes/1)
    |> Enum.filter(&(&1 != nil))
  end

  @doc"""
  Get all actions for which number of flags is above the limit
  """
  def random(nb_actions) do
    UserAction
    |> join(:inner, [a], f in Flag, f.action_id == a.id)
    |> group_by([a, _], a.id)
    |> having_default_ban()
    |> or_having_ban_defined()
    |> preload([a, _], [:user])
    |> select([a, _], a)
    |> order_by(fragment("RANDOM()"))
    |> limit(^nb_actions)
    |> Repo.all()
    |> Enum.map(&load_changes/1)
    |> Enum.filter(&(&1 != nil))
  end

  defp having_default_ban(query),
    do: having(query, [a, f], count(f.id) >= @default_nb_flags_to_ban and not [a.type, a.entity] in @defined_actions)

  defp or_having_ban_defined(base_query) do
    Enum.reduce(@nb_flags_to_ban, base_query, fn {{action_type, entity}, nb_flags_to_ban}, query ->
      or_having(query, [a, f], a.type == ^action_type and a.entity == ^entity and count(f.id) >= ^nb_flags_to_ban)
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