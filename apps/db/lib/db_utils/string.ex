defmodule DB.Utils.String do
  @moduledoc"""
  String utils not included in base library
  """

  @doc"""
  Convert a string like "     aaa     bbb ccc  " into "aaa bbb ccc"

  ## Examples

      iex> DB.Utils.String.trim_all_whitespaces "     aaa     bbb ccc  "
      "aaa bbb ccc"
      iex> DB.Utils.String.trim_all_whitespaces ""
      ""
  """
  def trim_all_whitespaces(str),
    do: String.replace(String.trim(str), ~r/\s+/, " ")
end