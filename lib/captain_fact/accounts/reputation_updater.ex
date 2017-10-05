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
  alias CaptainFact.Accounts.{User}
  alias CaptainFact.Actions.{UserAction, UsersActionsReport, ReportManager}

  @name __MODULE__
  @analyser_id UsersActionsReport.analyser_id(:reputation_updater)
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

    # Wildcards
    UserAction.type(:flag) =>         {  0  , -5   },

    # Special actions
    UserAction.type(:email_confirmed) => {  +15,  0 }
    # TODO
    # comment_banned:                 {  0  , -20   },
  }

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  @timeout 120_000 # 2 minutes
  def force_update() do
    GenServer.call(@name, :update_reputations, @timeout)
  end

  # Utils

  def action_reputation_change(type) when is_integer(type), do: Map.get(@actions, type)
  def action_reputation_change(type) when is_atom(type), do: action_reputation_change(UserAction.type(type))
  def action_reputation_change(type, entity) when is_integer(type) and is_integer(entity),
    do: get_in(@actions, [type, entity])
  def action_reputation_change(type, entity) when is_atom(type) and is_atom(entity),
    do: action_reputation_change(UserAction.type(type), UserAction.entity(entity))

  def actions, do: @actions

  # --- Server callbacks ---

  def handle_call(:update_reputations, _from, _state) do
    last_action_id = case ReportManager.get_last_report(@analyser_id) do
      nil -> 0
      %{status: :running} -> -1
      report -> report.last_action_id
    end

    unless last_action_id == -1, do: start_analysis(Repo.all(from a in UserAction, where: a.id > ^last_action_id))
    {:reply, :ok , :ok}
  end

  defp start_analysis([]), do: {:noreply, :ok}
  defp start_analysis(actions) do
    Logger.info("[ReputationUpdater] Update reputations")
    report = ReportManager.create_report!(@analyser_id, :running, actions)
    nb_users_updated = do_update_reputations(actions)

    # Update report
    ReportManager.update_report!(report, %{
      nb_users: nb_users_updated,
      run_duration: NaiveDateTime.diff(NaiveDateTime.utc_now(), report.inserted_at),
      status: UsersActionsReport.status(:success)
    })
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
    |> Enum.filter(fn {_, diff} -> diff != 0 end)
    |> Enum.map(fn {user_id, diff} ->
         User
         |> where(id: ^user_id)
         |> Repo.update_all(inc: [reputation: diff])
         |> elem(0)
       end)
    |> Enum.sum()
  end

  defp changes_updater(changes, _, 0), do: changes
  defp changes_updater(changes, key, diff), do: Map.update(changes, key, diff, &(&1 + diff))

  defp reputation_changes(%{type: type, entity: entity}) do
    case Map.get(@actions, type) do
      nil -> {0, 0}
      res when is_map(res) -> Map.get(res, entity) || {0, 0}
      res when is_tuple(res) -> res
    end
  end
end
