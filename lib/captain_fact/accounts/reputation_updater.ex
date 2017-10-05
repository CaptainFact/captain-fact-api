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
  alias CaptainFact.Actions.{UserAction, UsersActionsReport}

  @name __MODULE__
  @analyser_id UsersActionsReport.analyser_id(:reputation_updater)
#  @max_daily_reputation_gain 30
  @actions %{
    UserAction.type(:vote_up) => %{
      UserAction.entity(:comment) =>  {  0  , +2  },
      UserAction.entity(:fact) =>     {  0  , +3  },
    },
    UserAction.type(:vote_down) => %{
      UserAction.entity(:comment) =>  {  -1 , -2   },
      UserAction.entity(:fact) =>     {  -1 , -3   }
    },
    UserAction.type(:flag) => %{
      UserAction.entity(:comment) =>  {  0 , -5   },
      UserAction.entity(:fact) =>     {  0 , -5   }
    },

    # Special actions
    UserAction.type(:email_confirmed) => %{
      UserAction.entity(:user) =>     {  +15,  0   }
    }
    # TODO
#    comment_banned:           {  0  , -20   },
  }

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  # Static API

  @timeout 120_000 # 2 minutes
  def force_update() do
    GenServer.call(@name, :update_reputations, @timeout)
  end

  def action_reputation_change(type, entity) when is_integer(type) and is_integer(entity),
    do: get_in(@actions, [type, entity])
  def action_reputation_change(type, entity) when is_atom(type) and is_atom(entity),
    do: action_reputation_change(UserAction.type(type), UserAction.entity(entity))

  def actions, do: @actions

  # --- Server callbacks ---

  def handle_call(:update_reputations, _from, _state) do
    # TODO lock table ?
    # TODO setup a daily limit
    last_action_id =
      UsersActionsReport
      |> where([r], r.analyser_id == ^@analyser_id)
      |> order_by([r], desc: r.id)
      |> limit(1)
      |> Repo.one()
      |> case do
           nil -> 0
           report -> report.last_action_id
         end


    start_analysis(Repo.all(from a in UserAction, where: a.id > ^last_action_id))
    {:reply, :ok , :ok}
    # TODO Schedule next run
  end

  defp start_analysis([]), do: {:noreply, :ok}
  defp start_analysis(actions) do
    # TODO update in transaction
    Logger.info("[ReputationUpdater] Update reputations")
    start_time = :os.system_time(:seconds)
    last_action_id = Enum.max(actions, &(&1.id)).id
    report = Repo.insert!(UsersActionsReport.changeset(%UsersActionsReport{}, %{
      analyser_id: @analyser_id,
      nb_actions: Enum.count(actions),
      last_action_id: last_action_id,
      status: UsersActionsReport.status(:running)
    }))

    # Build map like: user_id => total_reputation_change
    nb_users_updated =
      Enum.reduce(actions, %{}, fn (action, all_changes) ->
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
      end)
      |> Enum.count()

    # Update report
    Repo.update!(UsersActionsReport.changeset(report, %{
      nb_users: nb_users_updated,
      run_duration: :os.system_time(:seconds) - start_time,
      status: UsersActionsReport.status(:success)
    }))
  end

  defp changes_updater(changes, _, 0), do: changes
  defp changes_updater(changes, key, diff), do: Map.update(changes, key, diff, &(&1 + diff))

  defp reputation_changes(%{type: type, entity: entity}) do
    case Map.get(@actions, type) do
      nil -> {0, 0}
      res -> Map.get(res, entity) || {0, 0}
    end
  end
end
