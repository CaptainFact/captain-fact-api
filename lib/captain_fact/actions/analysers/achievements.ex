defmodule CaptainFact.Actions.Analysers.Achievements do
  @moduledoc """
  Checks for special actions or actions combinations that could trigger an achievement
  """

  use GenServer

  require Logger
  import Ecto.Query
  import CaptainFact.Accounts, only: [unlock_achievement: 2]

  alias CaptainFact.Repo
  alias CaptainFact.Accounts.User
  alias CaptainFact.Actions.{UserAction, UsersActionsReport, ReportManager}

  @name __MODULE__
  @analyser_id UsersActionsReport.analyser_id(__MODULE__)
  @action_email_confirmed UserAction.type(:email_confirmed)
  @watched_action_types [@action_email_confirmed]

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  @timeout 120_000 # 2 minute
  def force_update() do
    GenServer.call(@name, :update_flags, @timeout)
  end

  # --- Server callbacks ---

  def handle_call(:update_flags, _from, _state) do
    last_action_id = ReportManager.get_last_action_id(@analyser_id)
    unless last_action_id == -1 do
      UserAction
      |> where([a], a.id > ^last_action_id)
      |> where([a], a.type in ^@watched_action_types)
      |> Repo.all()
      |> start_analysis()
    end
    {:reply, :ok , :ok}
  end

  defp start_analysis([]), do: :ok
  defp start_analysis(actions) do
    Logger.info("[Analysers.Achievements] Updating achievements")
    Enum.map(actions, fn
      %{type: @action_email_confirmed, user_id: id} -> unlock_achievement(Repo.get!(User, id), "not-a-robot")
      _ -> nil
    end)
  end
end