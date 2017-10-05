defmodule CaptainFact.Accounts.ReputationUpdater do
  @moduledoc """
  Updates a user reputation asynchronously, verifying at the same time that the maximum reputation
  gain per day quota is respected.
  State is a map like : `%{user_id: today_reputation_gain}`
  """

  use GenServer

  require Logger
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Accounts.{User, UserState}

  @name __MODULE__
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
    comment_banned:           {  0   , -20   },
    comment_flagged:          {  0   , -5    },
    email_confirmed:          {  0   , +15   }
  }

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  # Static API

  def max_daily_reputation_gain, do: @max_daily_reputation_gain
  def actions, do: @actions
  def action_target_reputation_change(action), do: elem(Map.get(@actions, action), 1)
  def get_today_reputation_gain(user), do: UserState.get(user_id(user), @user_state_key, 0)
  def wait_queue(), do: GenServer.call(@name, {:ping})

  # Async methods

  def register_action(source_user, target_user, action) when is_atom(action) do
    {source_change, target_change} = Map.get(@actions, action)
    GenServer.cast(@name, {:register_change, user_id(source_user), source_change})
    GenServer.cast(@name, {:register_change, user_id(target_user), target_change})
  end

  def register_action(target_user, action) when is_atom(action) do
    change = action_target_reputation_change(action)
    GenServer.cast(@name, {:register_change, user_id(target_user), change})
  end

  # --- Server callbacks ---

  def handle_cast({:register_change, _, 0}, _state), do: {:noreply, :ok}
  def handle_cast({:register_change, user_id, change}, _state) do
    # Get max reputation gain from user state and updates it ({action_gain, new_daily_gain})
    real_change = UserState.get_and_update(user_id, @user_state_key, fn
      today_gain when is_nil(today_gain) ->
        {change, change}
      today_gain when today_gain + change <= @max_daily_reputation_gain ->
        {change, today_gain + change}
      today_gain when today_gain >= @max_daily_reputation_gain ->
        {0, @max_daily_reputation_gain}
      today_gain ->
        {@max_daily_reputation_gain - today_gain , @max_daily_reputation_gain}
    end)
    db_update_reputation(user_id, real_change)
    {:noreply, :ok}
  end

  def handle_call({:ping}, _caller, _state), do: {:reply, :ok, :ok}

  # --- Methods ---

  defp db_update_reputation(_user_id, 0), do: true
  defp db_update_reputation(user_id, reputation_change) do
    try do
      Repo.transaction(fn ->
        user =
          User
          |> where(id: ^user_id)
          |> lock("FOR UPDATE")
          |> Repo.one!()

        new_reputation = user.reputation + reputation_change
        Repo.update(User.reputation_changeset(user, %{reputation: new_reputation}))
      end)
    rescue
      _ ->
        Logger.warn("DB reputation update (#{reputation_change}) for user #{user_id} failed")
        Logger.debug(inspect(System.stacktrace(), pretty: true))
    end
  end

  defp user_id(%User{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id
end
