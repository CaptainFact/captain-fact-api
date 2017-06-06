defmodule CaptainFact.ReputationUpdater do
  @moduledoc """
  Updates a user reputation asynchronously, verifying at the same time that the maximum reputation
  gain per day quota is respected
  """

  require Logger
  import Ecto.Query
  alias CaptainFact.{ Repo, User }

  @name __MODULE__
  @max_daily_reputation_gain 30
  @actions %{
    comment_vote_up: +2,
    comment_vote_down: -2,
    comment_vote_down_to_up: +4,
    comment_vote_up_to_down: -4,
    fact_vote_up: +3,
    fact_vote_down: -3,
    fact_vote_down_to_up: +6,
    fact_vote_up_to_down: -6
  }

  def start_link() do
    Logger.info("[ReputationUpdater] Reputation updater started")
    Agent.start_link(fn -> %{} end, name: @name)
  end

  # --- API ---

  @doc """
  (!) ⚡ Should **never** be called directly
  This method in only intended to be called by a scheduler to run 1 time a day
  """
  def reset() do
    Agent.update(@name, &do_reset(&1))
  end

  def register_change(user = %User{}, action) when is_atom(action) do
    Agent.update(@name, &do_add_action(&1, user.id, action))
  end

  # --- Methods ---
  defp do_reset(_state) do
    Logger.info("[ReputationUpdater] Reset maximum reputation quota")
    %{}
  end

  defp do_add_action(state, user_id, action) do
    today_gain = Map.get(state, user_id, 0)
    if today_gain >= @max_daily_reputation_gain do
      Logger.debug("[ReputationUpdater] User #{user_id} has already gained its max reputation for today")
      state
    else
      case Map.get(@actions, action) do
        nil ->
          Logger.error("[ReputationUpdater] Unknow user_id action '#{action}'")
          state
        reputation_change ->
          action_gain = cond do
            today_gain + reputation_change < @max_daily_reputation_gain -> reputation_change
            true -> @max_daily_reputation_gain - today_gain
          end
          Logger.debug("[ReputationUpdater] User #{user_id} gain #{action_gain} reputation")
          {:ok, _} = do_update_reputation(user_id, action_gain)
          Map.update(state, user_id, 0, &(&1 + action_gain))
      end
    end
  end

  defp do_update_reputation(user_id, reputation_change) do
    Repo.transaction(fn ->
      user =
        User
        |> where(id: ^user_id)
        |> lock("FOR UPDATE")
        |> Repo.one!()
      new_reputation = user.reputation + reputation_change
      Repo.update!(User.reputation_changeset(user, %{reputation: new_reputation}))
    end)
  end
end
