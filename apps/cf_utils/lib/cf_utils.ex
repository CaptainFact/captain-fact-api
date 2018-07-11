defmodule CF.Utils do
  @moduledoc """
  Helpers / utils functions 
  """

  @doc """
  Transform all map binary indexes to atoms. Use this function carefuly,
  generating too much atoms (for example when accepting user's input) can
  result in terrible performances issues.

  ## Examples

    iex> CF.Utils.map_string_keys_to_atom_keys(%{"test" => %{"ok" => 42}})
    %{test: %{ok: 42}}

  """
  def map_string_keys_to_atom_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, result ->
      atom_key = convert_key_to_atom(key)
      converted_value = map_string_keys_to_atom_keys(value)
      Map.put(result, atom_key, converted_value)
    end)
  end

  def map_string_keys_to_atom_keys(value),
    do: value

  # Convert key to atom if key is in binary format

  defp convert_key_to_atom(key) when is_binary(key),
    do: String.to_existing_atom(key)

  defp convert_key_to_atom(key) when is_atom(key),
    do: key
end
