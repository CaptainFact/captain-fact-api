defmodule CaptainFact.Actions.Analysers.Flags do
  @moduledoc """
  Analyse flags periodically to ban innapropriate content
  """

  use GenServer

  require Logger
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Comments.Comment
  alias CaptainFact.Actions.{UserAction, UsersActionsReport, ReportManager, Flagger}

  @name __MODULE__
  @analyser_id UsersActionsReport.analyser_id(__MODULE__)
  @comments_nb_flags_to_ban 5

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  @timeout 60_000 # 1 minute
  def update() do
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
      |> Repo.all(log: false)
      |> start_analysis()
    end
    {:reply, :ok , :ok}
  end

  defp start_analysis([]), do: :ok
  defp start_analysis(actions) do
    Logger.info("[Analyser.Flags] Update flags")
    report = ReportManager.create_report!(@analyser_id, :running, actions)
    nb_entities_banned = do_update_flags(actions)
    ReportManager.set_success!(report, nb_entities_banned)
  end

  # Update flags, return the number of updated users
  defp do_update_flags(actions) do
    actions
    |> Enum.group_by(&(&1.entity))
    |> Enum.map(fn {entity, actions} ->
         actions
         |> Enum.uniq_by(&(&1.entity_id))
         |> Enum.map(&(update_entity_flags(entity, &1)))
         |> Enum.sum()
       end)
    |> Enum.sum()
  end

  @comment_entity UserAction.entity(:comment)
  defp update_entity_flags(@comment_entity, %UserAction{entity_id: comment_id}) do
    nb_flags = Flagger.get_nb_flags(:create, :comment, comment_id)
    if nb_flags >= @comments_nb_flags_to_ban do
      # Ban comment
      {nb_updated, _} = Repo.update_all((
        from c in Comment,
             where: c.id == ^comment_id,
             where: c.is_banned == false
        ), [set: [is_banned: true]]
      )
      if nb_updated == 1 do
        broadcast_ban(:comment, comment_id)
        # TODO Record comment banned action
      end
      nb_updated
    else
      0
    end
  end

  def broadcast_ban(:comment, comment_id) do
    comment_context = Repo.one!(
      from c in Comment,
      join: s in CaptainFact.Speakers.Statement, on: c.statement_id == s.id,
      where: c.id == ^comment_id,
      select: %{video_id: s.video_id, statement_id: s.id}
    )
    # TODO Use a event bus here
    CaptainFactWeb.Endpoint.broadcast(
      "comments:video:#{CaptainFact.Videos.VideoHashId.encode(comment_context.video_id)}", "comment_removed",
      %{id: comment_id, statement_id: comment_context.statement_id}
    )
  end
end