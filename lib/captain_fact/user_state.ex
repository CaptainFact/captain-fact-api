defmodule CaptainFact.UserState do
  require Logger
  alias CaptainFact.User

  @name __MODULE__

  def start_link() do
    Logger.info("[UserState] Starting")
    Agent.start_link(fn -> %{} end, name: @name)
  end

  def get(user = %User{}, key, default \\ nil) when is_atom(key) do
    Agent.get(user_agent(user), &Map.get(&1, key, default))
  end

  def update(user = %User{}, key, initial, func) when is_atom(key) and is_function(func) do
    Agent.update(user_agent(user), &Map.update(&1, key, initial, func))
  end

  def get_and_update(user = %User{}, key, func) when is_atom(key) and is_function(func) do
    Agent.get_and_update(user_agent(user), fn user_state ->
      Map.get_and_update(user_state, key, func)
    end)
  end

  def user_agent(user = %User{}) do
    Agent.get_and_update(@name, fn state ->
      case Map.get(state, user.id) do
        nil ->
          {:ok, pid} = Agent.start_link(fn -> %{} end) # Cannot fail (no timeout)
          {pid, Map.put(state, user.id, pid)}
        pid ->
          {pid, state}
      end
    end)
  end

  @doc """
  (!) ⚡ Should **never** be called directly
  This method in only intended to be called by a scheduler to run 1 time a day
  """
  def reset() do
    Logger.info("[UserState] Reset all users states")
    Agent.update(@name, fn state ->
      state
      |> Enum.map(fn {_user_id, pid} -> Agent.stop(pid) end)
      %{}
    end)
  end
end