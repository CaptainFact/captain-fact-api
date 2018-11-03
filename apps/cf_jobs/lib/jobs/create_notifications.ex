defmodule CF.Jobs.CreateNotifications do
  @moduledoc """
  Eat `UserAction` items, digest them using `Subscriptions` and poop
  notifications in Database.

  It only watches for actions that can be matched with `SubscriptionMatcher`
  so if you're looking for notifications built for things like email_confirmed
  or new_achievement, they're not dispatched from here.

  This module also doesn't care about how notifications will later
  be delivered.
  """

  @behaviour CF.Jobs.Job

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.UsersActionsReport
  alias DB.Schema.UserAction
  alias DB.Schema.Notification

  alias CF.Actions
  alias CF.Notifications.SubscriptionsMatcher
  alias CF.Notifications.NotificationBuilder

  alias CF.Jobs.ReportManager

  @name :create_notifications
  @analyser_id UsersActionsReport.analyser_id(@name)

  # Define entities that are watched for changes
  @watched_entities [:video, :statement, :comment]

  # Define watched action types
  @watched_action_types [:create, :add, :remove, :restore]

  # --- Client API ---

  @spec name() :: :create_notifications
  def name, do: @name

  @spec start_link() :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec init(any()) :: {:ok, any()}
  def init(args) do
    {:ok, args}
  end

  # 2 minutes
  @timeout 120_000
  def update() do
    GenServer.call(__MODULE__, :update, @timeout)
  end

  # --- Server callbacks ---

  def handle_call(:update, _from, _state) do
    case ReportManager.get_last_action_id(@analyser_id) do
      -1 ->
        # Already running, ignore
        nil

      0 ->
        # First run, don't generate notifications for old actions
        actions = DB.Repo.all(UserAction)

        ReportManager.create_report!(
          @analyser_id,
          :success,
          actions,
          %{nb_actions: 0, run_duration: 0}
        )

      last_action_id ->
        UserAction
        |> where([a], a.id > ^last_action_id)
        |> Actions.matching_types(@watched_action_types)
        |> Actions.matching_entities(@watched_entities)
        |> Repo.all(log: false)
        |> start_analysis()
    end

    {:reply, :ok, :ok}
  end

  defp start_analysis([]), do: {:noreply, :ok}

  defp start_analysis(actions) do
    Logger.info("[Jobs.CreateNotifications] Update")
    report = ReportManager.create_report!(@analyser_id, :running, actions)
    {:ok, nb_updated} = process_actions(actions)
    ReportManager.set_success!(report, nb_updated)
  end

  defp process_actions(actions) do
    actions
    |> Enum.map(&build_notifications_for_action/1)
    |> List.flatten()
    |> insert_notifications()
  end

  defp build_notifications_for_action(action) do
    action
    |> SubscriptionsMatcher.match_action()
    |> Enum.map(&NotificationBuilder.for_subscribed_action(action, &1))
  end

  @spec insert_notifications([map()]) :: {:ok, integer()}
  defp insert_notifications(notifications_params) do
    {count, _} = DB.Repo.insert_all(Notification, notifications_params)
    {:ok, count}
  end
end
