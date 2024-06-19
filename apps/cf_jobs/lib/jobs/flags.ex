defmodule CF.Jobs.Flags do
  @moduledoc """
  Analyse flags periodically to report innapropriate content

  TODO: Broadcast comment update
  """

  @behaviour CF.Jobs.Job

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.UserAction
  alias DB.Schema.UsersActionsReport

  alias CF.Moderation.Flagger
  alias CF.Moderation

  alias CF.Jobs.ReportManager

  @name :flags
  @analyser_id UsersActionsReport.analyser_id(@name)

  # --- Client API ---

  def name, do: @name

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  # 1 minute
  @timeout 60_000
  def update() do
    GenServer.call(__MODULE__, :update_flags, @timeout)
  end

  # --- Server callbacks ---

  def handle_call(:update_flags, _from, _state) do
    last_action_id = ReportManager.get_last_action_id(@analyser_id)

    unless last_action_id == -1 do
      UserAction
      |> where([a], a.id > ^last_action_id)
      |> where([a], a.type == ^:flag)
      |> Repo.all(log: false)
      |> start_analysis()
    end

    {:reply, :ok, :ok}
  end

  defp start_analysis([]), do: :ok

  defp start_analysis(actions) do
    Logger.info("[Analyser.Flags] Update flags")
    report = ReportManager.create_report!(@analyser_id, :running, actions)
    nb_entities_reported = do_update_flags(actions)
    ReportManager.set_success!(report, nb_entities_reported)
  end

  # Update flags, return the number of updated users
  defp do_update_flags(actions) do
    actions
    |> Enum.group_by(& &1.entity)
    |> Enum.map(fn {entity, actions} ->
      actions
      |> Enum.uniq_by(& &1.comment_id)
      |> Enum.map(&update_entity_flags(entity, &1))
      |> Enum.sum()
    end)
    |> Enum.sum()
  end

  # Check for flags on comments
  defp update_entity_flags(:comment, %UserAction{comment_id: comment_id}) do
    nb_flags = Flagger.get_nb_flags(:create, :comment, comment_id)

    with true <- nb_flags >= Moderation.nb_flags_to_report(:create, :comment),
         {:ok, _} <- Moderation.ban_comment(comment_id) do
      1
    else
      _ -> 0
    end
  end

  # Ignore other flags
  defp update_entity_flags(_, _), do: 0
end
