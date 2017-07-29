defmodule CaptainFact.Accounts.UsernameGenerator do
  @moduledoc """
  Generates a unique username based on user id
  """

  @name __MODULE__

  def start_link do
    Agent.start_link(
      fn -> Hashids.new(
        alphabet: "123456789abcdefghijklmnopqrstuvwxyz",
        salt: "C4pt41nUser"
      ) end, name: @name
    )
  end

  def generate(id) do
    "NewUser-#{encode(id)}"
  end

  @doc """
  Encode a given id
  ## Examples
      iex> CaptainFact.Accounts.UsernameGenerator.encode(42)
      "py7"
  """
  @spec encode(Integer.t) :: String.t
  def encode(id) do
    Agent.get(@name, &Hashids.encode(&1, id))
  end
end
