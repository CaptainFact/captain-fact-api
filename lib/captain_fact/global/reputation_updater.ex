defmodule CaptainFact.ReputationUpdater do
  @moduledoc """
  Updates a user reputation asynchronously, verifying at the same time that the maximum reputation
  gain per day quota is respected.
  State is a map like : `%{user_id: today_reputation_gain}`
  """

  require Logger
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.UserState
  alias CaptainFact.Web.User

  @max_daily_reputation_gain 30
  @user_state_key :today_reputation_gain
  @actions %{
    # :action_atom            {source, target}
    comment_vote_up:          {  0   , +2    },
    comment_vote_down:        { -1   , -2    },
    comment_vote_down_to_up:  { +1   , +4    },
    comment_vote_up_to_down:  { -2   , -4    },
    fact_vote_up:             {  0   , +3    },
    fact_vote_down:           { -1   , -3    },
    fact_vote_down_to_up:     { +1   , +6    },
    fact_vote_up_to_down:     {  0   , -6    },
    # Actions without source
    comment_banned:           {  0   , -20   }
  }

  # --- API ---

  def register_action(source_user, target_user, action, async \\ true)
  when is_atom(action) do
    {source_change, target_change} = Map.get(@actions, action)
    tasks = [
      fn -> register_change(user_id(source_user), source_change) end,
      fn -> register_change(user_id(target_user), target_change) end
    ]
    if async,
      do: Enum.map(tasks, &Task.start_link/1),
      else: Enum.map(tasks, &Task.async/1) |> Enum.map(&Task.await/1)
  end

  def register_action_without_source(target_user, action, async \\ true) do
    change = elem(Map.get(@actions, action), 1)
    change_func = fn -> register_change(user_id(target_user), change) end
    if async, do: Task.start_link(change_func), else: change_func.()
  end

  def get_today_reputation_gain(user),
    do: UserState.get(user_id(user), @user_state_key, 0)

  def max_daily_reputation_gain(), do: @max_daily_reputation_gain
  def actions(), do: @actions

  # --- Methods ---

  defp user_id(%User{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id

  defp register_change(user_id, reputation_change) when is_integer(reputation_change) do
    real_change = UserState.get_and_update(user_id, @user_state_key, fn
      today_gain when is_nil(today_gain) ->
        {reputation_change, reputation_change}
      today_gain when today_gain + reputation_change <= @max_daily_reputation_gain ->
        {reputation_change, today_gain + reputation_change}
      today_gain when today_gain >= @max_daily_reputation_gain ->
        {0, @max_daily_reputation_gain}
      today_gain ->
        {@max_daily_reputation_gain - today_gain , @max_daily_reputation_gain}
    end)
    db_update_reputation(user_id, real_change)
  end

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
