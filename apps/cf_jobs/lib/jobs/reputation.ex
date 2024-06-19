defmodule CF.Jobs.Reputation do
  @moduledoc """
  Updates a user reputation periodically, verifying at the same time that the maximum reputation
  gain per day quota is respected.
  """

  @behaviour CF.Jobs.Job

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias DB.Schema.UserAction
  alias DB.Schema.UsersActionsReport
  alias CF.Actions

  alias CF.Actions.ReputationChange
  alias CF.Jobs.ReportManager

  @name :reputation
  @analyser_id UsersActionsReport.analyser_id(@name)

  @daily_gain_limit ReputationChange.daily_gain_limit()
  @daily_loss_limit ReputationChange.daily_loss_limit()

  # --- Client API ---

  def name, do: @name

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  # 2 minutes
  @timeout 120_000
  def update() do
    GenServer.call(__MODULE__, :update_reputations, @timeout)
  end

  def reset_daily_limits() do
    GenServer.call(__MODULE__, :reset_daily_limits, @timeout)
  end

  @doc """
  Adjust reputation change based on user's today reputation changes

  ## Examples

      iex> import CF.Jobs.Reputation
      iex> import CF.Actions.ReputationChange
      iex> # Nothing special when not hitting the limit, just returns change
      iex> calculate_adjusted_diff(3, 0)
      3
      iex> calculate_adjusted_diff(-4, 0)
      -4
      iex> # Gain limit
      iex> calculate_adjusted_diff(5, daily_gain_limit())
      0
      iex> calculate_adjusted_diff(-5, daily_gain_limit())
      -5
      iex> calculate_adjusted_diff(5, daily_gain_limit() - 4)
      4
      iex> calculate_adjusted_diff(-5, daily_gain_limit() - 1)
      -5
      iex> calculate_adjusted_diff(1, daily_gain_limit() + 5)
      0
      iex> # Loss limit
      iex> calculate_adjusted_diff(5, daily_loss_limit())
      5
      iex> calculate_adjusted_diff(-5, daily_loss_limit())
      0
      iex> calculate_adjusted_diff(5, daily_loss_limit() + 1)
      5
      iex> calculate_adjusted_diff(-5, daily_loss_limit() + 1)
      -1
      iex> calculate_adjusted_diff(-1, daily_loss_limit() - 5)
      0
  """
  def calculate_adjusted_diff(0, _),
    do: 0

  def calculate_adjusted_diff(change, today_change)
      when change > 0 and today_change >= @daily_gain_limit,
      do: 0

  def calculate_adjusted_diff(change, today_change)
      when change < 0 and today_change <= @daily_loss_limit,
      do: 0

  def calculate_adjusted_diff(change, today_change) when change > 0,
    do: min(change, @daily_gain_limit - today_change)

  def calculate_adjusted_diff(change, today_change) when change < 0,
    do: max(change, @daily_loss_limit - today_change)

  # --- Server callbacks ---

  def handle_call(:update_reputations, _from, _state) do
    last_action_id = ReportManager.get_last_action_id(@analyser_id)

    unless last_action_id == -1 do
      UserAction
      |> where([a], a.id > ^last_action_id)
      |> Actions.matching_types(ReputationChange.actions_types())
      |> Repo.all(log: false)
      |> start_analysis()
    end

    {:reply, :ok, :ok}
  end

  def handle_call(:reset_daily_limits, _from, _state) do
    Logger.info("[Jobs.Reputation] Reset daily limits")

    User
    |> where([u], u.today_reputation_gain != 0)
    |> Repo.update_all(set: [today_reputation_gain: 0])

    {:reply, :ok, :ok}
  end

  defp start_analysis([]), do: {:noreply, :ok}

  defp start_analysis(actions) do
    Logger.info("[Jobs.Reputation] Update reputations")
    report = ReportManager.create_report!(@analyser_id, :running, actions)
    nb_users_updated = do_update_reputations(actions)
    ReportManager.set_success!(report, nb_users_updated)
  end

  # Update reputations, return the number of updated users
  defp do_update_reputations(actions) do
    actions
    |> Enum.reduce(%{}, &group_changes_by_user/2)
    |> Enum.map(&apply_reputation_diff/1)
    |> Enum.count(&(&1 != false))
  end

  def group_changes_by_user(action, changes) do
    {source_change, target_change} = ReputationChange.for_action(action)

    changes
    |> changes_updater(action.user_id, source_change)
    |> changes_updater(action.target_user_id, target_change)
  end

  defp apply_reputation_diff({user_id, diff}) do
    Repo.transaction(fn ->
      User
      |> select([:id, :reputation, :today_reputation_gain])
      |> lock("FOR UPDATE")
      |> Repo.get(user_id)
      |> apply_adjusted_reputation_diff(diff)
    end)
  end

  # User may have deleted its account. Ignore him/her
  defp apply_adjusted_reputation_diff(nil, _),
    do: false

  # Ignore null reputation changes
  defp apply_adjusted_reputation_diff(_, 0),
    do: false

  # Ignore update if limit has already been reached
  defp apply_adjusted_reputation_diff(%{today_reputation_gain: today_gain}, change)
       when (change > 0 and today_gain >= @daily_gain_limit) or
              (change < 0 and today_gain <= @daily_loss_limit),
       do: false

  # Limit gains to `@daily_gain_limit` or `@daily_loss_limid`
  defp apply_adjusted_reputation_diff(user = %{today_reputation_gain: today_change}, change) do
    adjusted_diff = calculate_adjusted_diff(change, today_change)
    do_update_user_reputation(user, adjusted_diff)
  end

  defp do_update_user_reputation(user, change) do
    Repo.update(User.reputation_changeset(user, change), log: false)
  end

  defp changes_updater(changes, nil, _),
    do: changes

  defp changes_updater(changes, _, 0),
    do: changes

  defp changes_updater(changes, key, diff),
    do: Map.update(changes, key, diff, &(&1 + diff))
end
