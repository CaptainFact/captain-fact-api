defmodule CF.Actions.ReputationChange do
  @moduledoc """
  Calculate reputation changes.
  """

  import Ecto.Query
  alias DB.Schema.{User, UserAction}
  alias CF.Actions
  alias CF.Actions.ReputationChangeConfigLoader
  alias CF.Actions.ReputationChange

  # Reputation changes definition
  # @external_resource specify the file dependency to compiler
  # See https://hexdocs.pm/elixir/Module.html#module-external_resource
  # We load a file with atoms keys from YAML and then convert all keys to their
  # numerical value.
  @reputations_file Path.join(:code.priv_dir(:cf), "reputation_changes.yaml")
  @external_resource @reputations_file
  @actions ReputationChangeConfigLoader.load(@reputations_file)
  @actions_types Map.keys(@actions)

  # Define limitations for reputation gain / loss
  @daily_gain_limit 25
  @daily_loss_limit -50

  @doc """
  Get a tuple with {self_reputation_change, target_reputation_change)
  for given action type / entity.
  """
  def for_action(%UserAction{type: type, entity: entity}) do
    for_action(type, entity)
  end

  def for_action(type) when is_atom(type),
    do: Map.get(@actions, type) || {0, 0}

  @spec for_action(atom(), atom()) :: any()
  def for_action(type, entity) when is_atom(type) and is_atom(entity) do
    case Map.get(@actions, type) do
      nil -> {0, 0}
      res when is_map(res) -> Map.get(res, entity) || {0, 0}
      res when is_tuple(res) -> res
    end
  end

  @doc """
  Get reputation change as an integer for admin action (email confirmed, abusive
  flag...etc)
  """
  def for_admin_action(type), do: elem(for_action(type), 1)

  @doc """
  Estimate total reputation change from given `actions`.
  (!) This function should only be used for informational puproses as it doesn't
  take into account the daily limitations.
  """
  def estimate_reputation_change(actions, user = %User{}) do
    Enum.reduce(actions, 0, fn action, total ->
      total + impact_on_user(action, user)
    end)
  end

  @doc """
  Same as `estimate_reputation_change/2` except it automatically fetch all
  actions between `datetime_start` and `datetime_end`.
  """
  def estimate_reputation_change_period(datetime_start, datetime_end, user) do
    UserAction
    |> Actions.about_user(user)
    |> Actions.matching_types(@actions_types)
    |> Actions.for_period(datetime_start, datetime_end)
    |> DB.Repo.all()
    |> estimate_reputation_change(user)
  end

  @doc """
  Calculate the impact of an action for given `user_id` without taking
  `today_reputation_gain` into account
  """
  def impact_on_user(action = %{user_id: user_id}, %User{id: user_id}) do
    action
    |> for_action()
    |> elem(0)
  end

  def impact_on_user(action = %{target_user_id: user_id}, %User{id: user_id}) do
    action
    |> for_action()
    |> elem(1)
  end

  def impact_on_user(_, _) do
    0
  end

  @doc """
  Return a list of all actions types known by reputation change calculator.
  """
  def actions_types, do: @actions_types

  @doc """
  Returns the full map of actions <> reputation changes
  """
  def actions, do: @actions

  def daily_gain_limit, do: @daily_gain_limit

  def daily_loss_limit, do: @daily_loss_limit

  def update_all_actions_reputations do
    Enum.each(ReputationChange.actions(), &update_for_actions_entry/1)
  end

  defp update_for_actions_entry(
         {action_type, {author_reputation_change, target_reputation_change}}
       ) do
    DB.Schema.UserAction
    |> where([a], a.type == ^dump_action_type!(action_type))
    |> DB.Repo.update_all(
      set: [
        author_reputation_change: author_reputation_change,
        target_reputation_change: target_reputation_change
      ]
    )
  end

  defp update_for_actions_entry({action_type, details}) when is_map(details) do
    Enum.each(details, fn {entity, {author_reputation_change, target_reputation_change}} ->
      DB.Schema.UserAction
      |> where(
        [a],
        a.type == ^dump_action_type!(action_type) and a.entity == ^dump_entity_type!(entity)
      )
      |> DB.Repo.update_all(
        set: [
          author_reputation_change: author_reputation_change,
          target_reputation_change: target_reputation_change
        ]
      )
    end)
  end

  defp dump_action_type!(action_type) do
    {:ok, action_type_id} = DB.Type.UserActionType.dump(action_type)
    action_type_id
  end

  defp dump_entity_type!(entity) do
    {:ok, entity_id} = DB.Type.Entity.dump(entity)
    entity_id
  end
end
