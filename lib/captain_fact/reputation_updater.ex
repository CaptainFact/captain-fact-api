defmodule CaptainFact.ReputationUpdater do
  @moduledoc """
  Updates a user reputation asynchronously, verifying at the same time that the maximum reputation
  gain per day quota is respected.
  State is a map like : `%{user_id: today_reputation_gain}`
  """

  require Logger
  import Ecto.Query
  alias CaptainFact.{ Repo, User, UserState }

  @max_daily_reputation_gain 30
  @user_state_key :today_reputation_gain
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

  # --- API ---

  def register_change(user = %User{}, action) when is_atom(action) do
    action_reputation_change = Map.get(@actions, action)
    if !action_reputation_change do
      Logger.error("[ReputationUpdater] Unknow user #{user.id} action '#{action}'")
    else
      real_change = UserState.get_and_update(user, @user_state_key, fn
        today_gain when is_nil(today_gain) ->
          {action_reputation_change, action_reputation_change}
        today_gain when today_gain + action_reputation_change <= @max_daily_reputation_gain ->
          {action_reputation_change, today_gain + action_reputation_change}
        today_gain when today_gain >= @max_daily_reputation_gain ->
          {0, @max_daily_reputation_gain}
        today_gain ->
          {@max_daily_reputation_gain - today_gain , @max_daily_reputation_gain}
      end)
      db_update_reputation(user.id, real_change)
    end
  end

  def get_today_reputation_gain(user = %User{}) do
    UserState.get(user, @user_state_key, 0)
  end

  def max_daily_reputation_gain(), do: @max_daily_reputation_gain
  def actions(), do: @actions

  # --- Methods ---
  defp db_update_reputation(_user_id, 0), do: true
  defp db_update_reputation(user_id, reputation_change) do
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
