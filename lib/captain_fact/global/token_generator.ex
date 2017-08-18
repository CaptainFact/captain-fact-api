defmodule CaptainFact.TokenGenerator do
  @doc """
  Generate a strong unique token
  """
  def generate(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end
end