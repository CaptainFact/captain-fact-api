defmodule StringUtils do
  @doc"""
  Convert a string like "     aaa     bbb ccc  " into "aaa bbb ccc"

  ## Examples

    iex> StringUtils.trim_all_whitespaces "     aaa     bbb ccc  "
    "aaa bbb ccc"
    iex> StringUtils.trim_all_whitespaces ""
    ""
  """
  def trim_all_whitespaces(str),
    do: String.replace(String.trim(str), ~r/\s+/, " ")
end