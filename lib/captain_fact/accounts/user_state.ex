defmodule CaptainFact.Accounts.UserState do
  @moduledoc """
  Store a state that is re-initialized every 24h. This is mainly intended to store info such as
  limitations for daily reputations gains or maximum number of votes for each day.

  ** (!) Should not be used directly outside of this folder **
  """

  require Logger

  @name __MODULE__

  def start_link() do
    Logger.info("[UserState] Start")
    Agent.start_link(fn -> %{} end, name: @name)
  end

  def get(user, key, default \\ nil) when is_atom(key) do
    user
    |> user_id()
    |> user_agent()
    |> Agent.get(&Map.get(&1, key, default))
  end

  def update(user, key, initial, func) when is_atom(key) and is_function(func) do
    user
    |> user_id()
    |> user_agent()
    |> Agent.update(&Map.update(&1, key, initial, func))
  end

  def get_and_update(user, key, func) when is_atom(key) and is_function(func) do
    user
    |> user_id()
    |> user_agent()
    |> Agent.get_and_update(&Map.get_and_update(&1, key, func))
  end

  @doc """
  (!) ⚡ Should **never** be called directly
  This method in only intended to be called by a scheduler to run 1 time a day
  """
  def reset() do
    Logger.info("[UserState] Reset all users state")
    Agent.update(@name, fn state ->
      Enum.map(state, fn {_user_id, pid} -> Agent.stop(pid) end)
      %{}
    end)
  end

  defp user_agent(user_id) do
    Agent.get_and_update(@name, fn state ->
      case Map.get(state, user_id) do
        nil ->
          {:ok, pid} = Agent.start_link(fn -> %{} end) # Cannot fail (no timeout)
          {pid, Map.put(state, user_id, pid)}
        pid ->
          {pid, state}
      end
    end)
  end

  defp user_id(%{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id
end