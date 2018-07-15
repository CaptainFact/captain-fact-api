defmodule CaptainFact.Actions.ReputationChangeConfigLoader do
  @moduledoc """
  Config loader for reputation changes
  """

  alias DB.Schema.UserAction

  @doc """
  Load a config and convert it using `convert/1`
  """
  def load(filename) do
    filename
    |> CF.Utils.load_yaml_config()
    |> convert()
  end

  @doc """
  Convert a config with atom keys to a config with integer indexes and tuples
  instead of lists.

  ## Examples

      iex> import CaptainFact.Actions.ReputationChangeConfigLoader, only: [convert: 1]
      iex> convert(%{abused_flag: [0,-5], vote_up: %{comment: [0, 2], fact: [0, 3]}})
      %{9 => %{4 => {0, 2}, 5 => {0, 3}}, 103 => {0, -5}}
  """
  def convert(base_config) do
    Enum.reduce(base_config, %{}, fn {atom_action_type, value}, actions_map ->
      Map.put(actions_map, UserAction.type(atom_action_type), convert_value(value))
    end)
  end

  defp convert_value(value) when is_list(value) do
    List.to_tuple(value)
  end

  defp convert_value(value) when is_map(value) do
    Enum.reduce(value, %{}, fn {entity, change_list}, action_changes ->
      Map.put(action_changes, UserAction.entity(entity), List.to_tuple(change_list))
    end)
  end
end
