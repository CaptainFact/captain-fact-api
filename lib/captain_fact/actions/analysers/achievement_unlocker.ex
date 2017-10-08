defmodule CaptainFact.Actions.Analysers.AchievementUnlocker do
  @moduledoc """
  Analyse flags periodically to ban innapropriate content
  """

  use GenServer

  require Logger
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Actions.{UserAction, UsersActionsReport, ReportManager}

  @name __MODULE__
  @analyser_id UsersActionsReport.analyser_id(__MODULE__)
  @comments_nb_flags_to_ban 3

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  @timeout 60_000 # 1 minute
  def force_update() do
    GenServer.call(@name, :update_flags, @timeout)
  end

  def comments_nb_flags_to_ban(), do: @comments_nb_flags_to_ban

  # --- Server callbacks ---

  def handle_call(:update_flags, _from, _state) do
    last_action_id = ReportManager.get_last_action_id(@analyser_id)
    unless last_action_id == -1 do
      UserAction
      |> where([a], a.id > ^last_action_id)
      |> where([a], a.type == ^UserAction.type(:flag))
      |> Repo.all()
      |> start_analysis()
    end
    {:reply, :ok , :ok}
  end

  defp start_analysis([]), do: :ok
  defp start_analysis(actions) do
    Logger.info("[Analysers.AchievementUnlocker] Updating achievements")

  end
end