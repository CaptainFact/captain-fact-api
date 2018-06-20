defmodule DB.Utils.TokenGenerator do
  @moduledoc"""
  Generate base64 unique tokens using :crypto.strong_rand_bytes/1
  """

  @doc """
  Generate a new token
  """
  def generate(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end
