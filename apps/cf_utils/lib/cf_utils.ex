defmodule CF.Utils do
  @moduledoc """
  Helpers / utils functions
  """

  @doc """
  Load a YAML map from given file and recursively convert all keys to atoms.
  (!) This function uses `String.to_existing_atom/1` so atom must already exist
  """
  def load_yaml_config(filename) do
    filename
    |> YamlElixir.read_all_from_file!()
    |> List.first()
    |> map_string_keys_to_atom_keys()
  end

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
    do: String.to_atom(key)

  defp convert_key_to_atom(key) when is_atom(key),
    do: key
end
