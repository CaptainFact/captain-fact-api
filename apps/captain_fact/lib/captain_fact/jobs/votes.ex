defmodule CaptainFact.Jobs.Votes do
  @moduledoc """
  Update votes at a certain interval
  """

  use GenServer

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.Comment
  alias DB.Schema.UserAction
  alias DB.Schema.UsersActionsReport

  alias CaptainFact.Actions.ReportManager


  @name __MODULE__
  @analyser_id UsersActionsReport.analyser_id(:votes)
  @entity_comment UserAction.entity(:comment)
  @entity_fact UserAction.entity(:fact)
  @watched_actions Enum.map([
    :vote_up, :vote_down, :self_vote, :revert_vote_up, :revert_vote_down, :revert_self_vote
  ], &UserAction.type/1)

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  def init(args) do
    {:ok, args}
  end

  @timeout 60_000 # 1 minute
  def update() do
    GenServer.call(@name, :update_votes, @timeout)
  end

  # --- Server callbacks ---

  def handle_call(:update_votes, _from, _state) do
    last_action_id = ReportManager.get_last_action_id(@analyser_id)
    unless last_action_id == -1 do
      UserAction
      |> where([a], a.id > ^last_action_id)
      |> where([a], a.type in ^@watched_actions)
      |> Repo.all(log: false) # Don't log this query (otherwise it would be triggered every 5sec)
      |> start_analysis()
    end
    {:reply, :ok , :ok}
  end

  defp start_analysis([]), do: nil
  defp start_analysis(actions) do
    Logger.info("[Jobs.Votes] Update votes scores")
    report = ReportManager.create_report!(@analyser_id, :running, actions)
    nb_entities_updated =
      actions
      |> Enum.group_by(&(&1.entity))
      |> Enum.map(fn {entity, actions} -> update_entity_votes(entity, actions) end)
      |> Enum.sum()

    # Update report
    ReportManager.set_success!(report, nb_entities_updated)
  end

  defp update_entity_votes(entity, actions) when entity in [@entity_comment, @entity_fact] do
    actions
    |> Enum.group_by(&(&1.context))
    |> Enum.map(fn {context, actions} -> update_comments_votes(context, actions) end)
    |> Enum.sum()
  end
  defp update_entity_votes(entity, _) do
    Logger.error("No vote analyser clause defined for #{entity}")
    0
  end

  defp update_comments_votes(nil, _), do: 0 # Should only happen in test
  defp update_comments_votes(context, actions) do
    updated_comments_ids =
      actions
      |> Enum.map(&(&1.entity_id))
      |> Enum.uniq()

    scores =
      Comment
      |> where([c], c.id in ^updated_comments_ids)
      |> join(:left, [c], v in fragment("
          SELECT    SUM(value) AS score, comment_id
          FROM      votes
          GROUP BY  comment_id
         "), v.comment_id == c.id)
      |> select([c, v], %{
          id: c.id,
          statement_id: c.statement_id,
          reply_to_id: c.reply_to_id,
          score: fragment("coalesce(score, ?)", 0)
         })
      |> Repo.all()

    case broadcast_channel(context) do
      nil -> nil
      channel -> CaptainFactWeb.Endpoint.broadcast(channel, "comments_scores_updated", %{comments: scores})
    end
    Enum.count(scores)
  end

  defp broadcast_channel("VD:" <> video_id) do
    "comments:video:#{DB.Type.VideoHashId.encode(String.to_integer(video_id))}"
  end
  defp broadcast_channel(_), do: nil
end