defmodule CF.Jobs.Moderation do
  @moduledoc """
  This job analyze moderation feebacks and ban or unreport comments accordingly.

  TODO: Broadcast updates
  TODO: This job does not use the ReportManager! (it should!)
  """

  @behaviour CF.Jobs.Job

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.ModerationUserFeedback
  alias DB.Schema.UserAction
  alias DB.Schema.Comment
  alias DB.Schema.Flag
  alias DB.Type.FlagReason

  alias CF.Actions.ActionCreator
  alias CF.Comments

  @name :moderation
  @min_nb_feedbacks_to_process_entry 3
  @refute_ban_under -0.66
  @confirm_ban_above 0.66

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
    GenServer.call(__MODULE__, :update, @timeout)
  end

  @doc """
  Calculate the strenght of the consensus from score (which is between -1.0 and 1.0) as a value between 0.0 and 1.0
  with 0.0 being the weakest consensus acceptable and 1.0 the strongest

  ## Examples

    iex> import CF.Jobs.Moderation
    iex> consensus_strength(confirm_ban_above())
    0.0
    iex> consensus_strength(refute_ban_under())
    0.0
    iex> consensus_strength(1)
    1.0
    iex> consensus_strength(-1.0)
    1.0
    iex> consensus_strength(confirm_ban_above() + ((1.0 - confirm_ban_above()) / 2.0))
    0.5
  """
  def consensus_strength(score) when score <= @refute_ban_under,
    do: consensus_strength(abs(score), abs(@refute_ban_under))

  def consensus_strength(score) when score >= @confirm_ban_above,
    do: consensus_strength(score, @confirm_ban_above)

  def consensus_strength(abs_score, min_val),
    do: Float.round((abs_score - min_val) * (1 / (1 - min_val)), 1)

  # Static accessors
  def min_nb_feedbacks_to_process_entry, do: @min_nb_feedbacks_to_process_entry
  def refute_ban_under, do: @refute_ban_under
  def confirm_ban_above, do: @confirm_ban_above

  # --- Internal API ---

  def handle_call(:update, _, _) do
    UserAction
    |> join(:inner, [a], uf in ModerationUserFeedback, uf.action_id == a.id)
    |> select([a, uf], %{
      action: %{
        id: a.id,
        user_id: a.user_id,
        type: a.type,
        entity: a.entity,
        comment_id: a.comment_id
      },
      results: %{
        nb_feedbacks: count(uf.id),
        feedbacks_sum: sum(uf.value)
      }
    })
    |> having([_, uf], count(uf.id) >= @min_nb_feedbacks_to_process_entry)
    |> group_by([a, _], a.id)
    |> Repo.all(log: false)
    |> Enum.map(&put_score_in_results/1)
    |> Enum.filter(&filter_with_consensus/1)
    |> Enum.map(&put_flag_reason_in_results/1)
    |> log_update()
    |> Enum.map(&process_entry/1)

    # credo:disable-for-previous-line

    {:reply, :ok, :ok}
  end

  defp log_update(actions) do
    if Enum.count(actions) != 0, do: Logger.info("[ModerationUpdater] Update")
    actions
  end

  # Score = sum of feedbacks values / number of feedbacks
  defp put_score_in_results(entry = %{results: %{nb_feedbacks: 0}}),
    do: put_in(entry, [:results, :score], 0)

  defp put_score_in_results(entry = %{results: res}),
    do: put_in(entry, [:results, :score], res.feedbacks_sum / res.nb_feedbacks)

  # Keep only entries with a consensus (either to ban or keep)
  defp filter_with_consensus(%{results: %{score: score}}),
    do: score <= @refute_ban_under or score >= @confirm_ban_above

  # Check which flag is most present. If there is an equality, which flag type
  # will be chosen is uncertain.
  defp put_flag_reason_in_results(entry = %{action: action}) do
    put_in(
      entry,
      [:results, :flag_reason],
      Repo.one(
        from(
          f in ModerationUserFeedback,
          where: f.action_id == ^action.id,
          group_by: f.flag_reason,
          select: f.flag_reason,
          order_by: [desc: count(f.id)],
          limit: 1
        )
      )
    )
  end

  # We can only moderate comment and sourced comment at the moment
  defp process_entry(entry = %{action: %{type: :create, entity: entity}})
       when entity in [:comment, :fact] do
    comment = Repo.get(Comment.with_statement(Comment), entry.action.comment_id)

    if comment do
      confirm_refute_dispatch(entry, comment)
    else
      Logger.warn("[ModerationUpdater] Can't find comment ##{entry.action.comment_id} for delete")
    end
  end

  defp process_entry(%{action: %{type: type, entity: entity}}) do
    Logger.warn("[ModerationUpdater] Got an unknown type/entity as Feedback: #{type}/#{entity}")
  end

  # Take an entry with established consensus and decide if we should confirm or refute
  defp confirm_refute_dispatch(%{action: action, results: results}, entity) do
    cond do
      results.score >= @confirm_ban_above ->
        confirm_ban(action, entity, results)

      results.score <= @refute_ban_under ->
        refute_ban(action, entity, results)

      true ->
        nil
    end
  end

  # Confirm ban
  defp confirm_ban(action, comment = %Comment{}, results) do
    # Get flagging users before deleting flags
    flagging_users_ids =
      Flag
      |> where([f], f.action_id == ^action.id)
      |> select([f], f.source_user_id)
      |> Repo.all()

    # Delete comment, all linked actions and flags
    Comments.admin_delete_comment(comment)

    # Record ban action
    Repo.insert(
      ActionCreator.action_ban(comment, ban_reason(results.flag_reason), %{
        "score" => results.score,
        "flag_reason" => results.flag_reason,
        "nb_feedbacks" => results.nb_feedbacks,
        "consensus_strength" => consensus_strength(results.score)
      })
    )

    # Record flags confirmations for flaggers to get reputation bonus
    record_flags_results(flagging_users_ids, Comment.type(comment), :confirmed_flag)
  end

  defp ban_reason(reason) do
    case FlagReason.label(reason) do
      "bad_language" -> :action_banned_bad_language
      "spam" -> :action_banned_spam
      "irrelevant" -> :action_banned_irrelevant
      "not_constructive" -> :action_banned_not_constructive
    end
  end

  # Abusive flags
  defp refute_ban(action, comment = %Comment{}, _) do
    # Set comment as not reported
    Repo.update(Ecto.Changeset.change(comment, is_reported: false))

    # Delete all flags and punish all users for abusive flags
    Flag
    |> where([f], f.action_id == ^action.id)
    |> Repo.delete_all(returning: [:source_user_id])
    # Repo.delete_all returns a tuple like {nb_updated, entries}
    |> elem(1)
    |> Enum.map(&Map.get(&1, :source_user_id))
    |> record_flags_results(Comment.type(comment), :abused_flag)

    # Delete all feedbacks
    Repo.delete_all(where(ModerationUserFeedback, [f], f.action_id == ^action.id))
  end

  # Record the flag result for all users
  defp record_flags_results(flagging_users_ids, entity_type, action_type) do
    targets = Enum.map(flagging_users_ids, &%{target_user_id: &1})

    Repo.insert_all(
      UserAction,
      Enum.map(targets, fn params ->
        Map.merge(params, %{
          user_id: nil,
          type: action_type,
          entity: entity_type,
          inserted_at: Ecto.DateTime.utc()
        })
      end)
    )
  end
end
