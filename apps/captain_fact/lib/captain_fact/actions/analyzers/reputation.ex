defmodule CaptainFact.Actions.Analyzers.Reputation do
  @moduledoc """
  Updates a user reputation periodically, verifying at the same time that the maximum reputation
  gain per day quota is respected.
  """

  use GenServer

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias CaptainFact.Accounts.{User}
  alias CaptainFact.Actions.{UserAction, UsersActionsReport, ReportManager}

  @name __MODULE__
  @analyser_id UsersActionsReport.analyser_id(__MODULE__)
  @daily_gain_limit 25
  @actions %{
    UserAction.type(:vote_up) => %{
      UserAction.entity(:comment) =>  {  0  , +2  },
      UserAction.entity(:fact) =>     {  0  , +3  },
    },
    UserAction.type(:vote_down) => %{
      UserAction.entity(:comment) =>  {  -1 , -2   },
      UserAction.entity(:fact) =>     {  -1 , -3   }
    },
    UserAction.type(:revert_vote_up) => %{
      UserAction.entity(:comment) =>  {  0  , -2  },
      UserAction.entity(:fact) =>     {  0  , -3  },
    },
    UserAction.type(:revert_vote_down) => %{
      UserAction.entity(:comment) =>  {  +1 , +2   },
      UserAction.entity(:fact) =>     {  +1 , +3   }
    },
    UserAction.type(:delete) => %{
      UserAction.entity(:comment) =>  {  -1 ,  0   },
    },

    # Special actions
    UserAction.type(:email_confirmed) => {  +15,  0 },
    # For reference and query. See `reputation_changes/1` for real implementation
    UserAction.type(:action_banned) => nil,
    UserAction.type(:abused_flag) => nil,
    UserAction.type(:confirmed_flag) => nil,
  }
  @actions_types Map.keys(@actions)

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  @timeout 120_000 # 2 minutes
  def update() do
    GenServer.call(@name, :update_reputations, @timeout)
  end

  def reset_daily_limits() do
    GenServer.call(@name, :reset_daily_limits, @timeout)
  end

  # Utils

  def action_reputation_change(type) when is_integer(type), do: Map.get(@actions, type)
  def action_reputation_change(type) when is_atom(type), do: action_reputation_change(UserAction.type(type))
  def action_reputation_change(type, entity) when is_integer(type) and is_integer(entity),
    do: get_in(@actions, [type, entity])
  def action_reputation_change(type, entity) when is_atom(type) and is_atom(entity),
    do: action_reputation_change(UserAction.type(type), UserAction.entity(entity))

  def actions, do: @actions

  def daily_gain_limit, do: @daily_gain_limit

  # --- Server callbacks ---

  def handle_call(:update_reputations, _from, _state) do
    last_action_id = ReportManager.get_last_action_id(@analyser_id)
    unless last_action_id == -1 do
      from(a in UserAction, where: a.id > ^last_action_id, where: a.type in @actions_types)
      |> Repo.all(log: false)
      |> start_analysis()
    end
    {:reply, :ok , :ok}
  end

  def handle_call(:reset_daily_limits, _from, _state) do
    Logger.info("[Analyzers.Reputation] Reset daily limits")
    User
    |> where([u], u.today_reputation_gain != 0)
    |> Repo.update_all(set: [today_reputation_gain: 0])
    {:reply, :ok , :ok}
  end

  defp start_analysis([]), do: {:noreply, :ok}
  defp start_analysis(actions) do
    Logger.info("[Analyzers.Reputation] Update reputations")
    report = ReportManager.create_report!(@analyser_id, :running, actions)
    nb_users_updated = do_update_reputations(actions)
    ReportManager.set_success!(report, nb_users_updated)
  end

  # Update reputations, return the number of updated users
  defp do_update_reputations(actions) do
    actions
    |> Enum.reduce(%{}, fn (action, all_changes) ->
         {source_change, target_change} = reputation_changes(action)
         all_changes
         |> changes_updater(action.user_id, source_change)
         |> changes_updater(action.target_user_id, target_change)
       end)
    |> Enum.map(fn {user_id, diff} ->
         User
         |> select([:id, :reputation, :today_reputation_gain])
         |> Repo.get(user_id)
         |> update_user_reputation(diff)
       end)
    |> Enum.count(&(&1 == true))
  end

  # User may have deleted its account. Ignore him/her
  defp update_user_reputation(nil, _), do: false
  # Ignore null reputation changes
  defp update_user_reputation(_, 0), do: false
  # No need to check anything when lowering reputation
  defp update_user_reputation(user, change) when change < 0, do: do_update_user_reputation(user, change)
  # Ignore update if limit has already been reached
  defp update_user_reputation(%{today_reputation_gain: today_gain}, _) when today_gain > @daily_gain_limit, do: false
  # Limit gains to `@daily_gain_limit`
  defp update_user_reputation(user = %{today_reputation_gain: today_gain}, change),
    do: do_update_user_reputation(user, min(change, @daily_gain_limit - today_gain))

  defp do_update_user_reputation(user, change) do
    case Repo.update(User.reputation_changeset(user, change), log: false) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp changes_updater(changes, nil, _), do: changes
  defp changes_updater(changes, _, 0), do: changes
  defp changes_updater(changes, key, diff), do: Map.update(changes, key, diff, &(&1 + diff))

  @collective_moderation_actions [
    UserAction.type(:action_banned),
    UserAction.type(:abused_flag),
    UserAction.type(:confirmed_flag)
  ]
  defp reputation_changes(%{type: type, entity: entity, changes: changes}) when type in @collective_moderation_actions,
    do: {0, CaptainFact.Moderation.Updater.reputation_change(type, entity, changes)}
  defp reputation_changes(%{type: type, entity: entity}) do
    case Map.get(@actions, type) do
      nil -> {0, 0}
      res when is_map(res) -> Map.get(res, entity) || {0, 0}
      res when is_tuple(res) -> res
    end
  end
end
