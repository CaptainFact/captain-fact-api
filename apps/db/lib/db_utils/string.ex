defmodule DB.Utils.String do
  @moduledoc """
  String utils not included in base library
  """

  @doc """
  Convert a string like "     aaa     bbb ccc  " into "aaa bbb ccc"

  ## Examples

      iex> DB.Utils.String.trim_all_whitespaces "     aaa     bbb ccc  "
      "aaa bbb ccc"
      iex> DB.Utils.String.trim_all_whitespaces ""
      ""
  """
  def trim_all_whitespaces(nil),
    do: nil

  def trim_all_whitespaces(str) do
    str
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end

  def upcase(nil), do: nil

  def upcase(str), do: String.upcase(str)
end
