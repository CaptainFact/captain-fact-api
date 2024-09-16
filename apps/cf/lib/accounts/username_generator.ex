defmodule CF.Accounts.UsernameGenerator do
  @moduledoc """
  Generates a unique username based on user id
  """

  @name __MODULE__
  @username_prefix "NewUser-"

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(_opts \\ []) do
    Agent.start_link(
      fn ->
        Hashids.new(
          alphabet: "123456789abcdefghijklmnopqrstuvwxyz",
          salt: "C4pt41nUser"
        )
      end,
      name: @name
    )
  end

  def generate(id) do
    @username_prefix <> encode(id)
  end

  def username_prefix(), do: @username_prefix

  @doc """
  Encode a given id
  ## Examples
      iex> CF.Accounts.UsernameGenerator.encode(42)
      "py7"
  """
  @spec encode(Integer.t()) :: String.t()
  def encode(id) do
    Agent.get(@name, &Hashids.encode(&1, id))
  end
end
