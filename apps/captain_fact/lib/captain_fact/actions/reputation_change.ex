defmodule CaptainFact.Actions.ReputationChange do
  @moduledoc """
  Calculate reputation changes.
  """

  alias DB.Schema.UserAction
  alias CaptainFact.Actions.ReputationChangeConfigLoader

  # Reputation changes definition
  # @external_resource specify the file dependency to compiler
  # See https://hexdocs.pm/elixir/Module.html#module-external_resource
  # We load a file with atoms keys from YAML and then convert all keys to their
  # numerical value.
  @reputations_file Path.join(:code.priv_dir(:captain_fact), "reputation_changes.yaml")
  @external_resource @reputations_file
  @actions ReputationChangeConfigLoader.load(@reputations_file)
  @actions_types Map.keys(@actions)

  @doc """
  Return a list of all actions types known by reputation change calculator.
  """
  def actions_types, do: @actions_types

  @doc """
  Get a tuple with {self_reputation_change, target_reputation_change)
  for given action type / entity.
  """
  def for_action(%UserAction{type: type, entity: entity}) do
    case Map.get(@actions, type) do
      nil -> {0, 0}
      res when is_map(res) -> Map.get(res, entity) || {0, 0}
      res when is_tuple(res) -> res
    end
  end

  def for_action(type) when is_atom(type),
    do: for_action(UserAction.type(type))

  def for_action(type) when is_integer(type),
    do: Map.get(@actions, type) || {0, 0}

  def for_action(type, entity) when is_atom(type) and is_atom(entity),
    do: for_action(UserAction.type(type), UserAction.entity(entity))

  def for_action(type, entity) when is_integer(type) and is_integer(entity),
    do: get_in(@actions, [type, entity]) || {0, 0}

  @doc """
  Get reputation change as an integer for admin action (email confirmed, abusive
  flag...etc)
  """
  def for_admin_action(type), do: elem(for_action(type), 1)
end
