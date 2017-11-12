defmodule CaptainFact.Moderation.Updater do
  use GenServer
  require Logger
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Actions.{UserAction, Flag, Recorder}
  alias CaptainFact.Moderation.UserFeedback
  alias CaptainFact.Comments
  alias CaptainFact.Comments.Comment

  @name __MODULE__
  @min_nb_feedbacks_to_take_action 3
  @refute_ban_under -0.66
  @confirm_ban_above 0.66

  @reputation_change_ranges %{
    UserAction.type(:action_banned) => -15..-25,
    UserAction.type(:abused_flag) => -10..-20,
    UserAction.type(:confirmed_flag) => 3..10
  }

  # --- Client API ---

  def start_link() do
    GenServer.start_link(@name, :ok, name: @name)
  end

  @timeout 60_000 # 1 minute
  def update() do
    GenServer.call(@name, :update, @timeout)
  end

  @doc"""
  Calculate reputation change based on consencus strength (see `get_consensus_strength/1`). The changes we get here
  (second parameter) are the ones we record in `take_action` with:
  `Recorder.admin_record!(ACTION_TYPE, :comment, %{target_user_id: comment.user_id, changes: CHANGES})`

  This method is called by reputation updater when updating reputation

  ## Examples

    iex> alias CaptainFact.Moderation.Updater
    iex> alias CaptainFact.Actions.UserAction
    iex> Updater.reputation_change(UserAction.type(:action_banned), nil, %{"score" => 1})
    -25
    iex> Updater.reputation_change(UserAction.type(:action_banned), nil, %{"score" => 0.66})
    -15
    iex> Updater.reputation_change(UserAction.type(:abused_flag), nil, %{"score" => 1})
    -20
    iex> Updater.reputation_change(UserAction.type(:abused_flag), nil, %{"score" => 0.66})
    -10
    iex> Updater.reputation_change(UserAction.type(:confirmed_flag), nil, %{"score" => 1})
    10
  """
  def reputation_change(action_type, _entity, _changes = %{"score" => score}) do
    min..max = @reputation_change_ranges[action_type]
    round(min + get_consensus_strength(score) * (max - min))
  end

  @doc"""
  Calculate the strenght of the consensus from score (which is between -1.0 and 1.0) as a value between 0.0 and 1.0
  with 0.0 being the weakest consensus acceptable and 1.0 the strongest

  ## Examples

    iex> alias CaptainFact.Moderation.Updater
    iex> Updater.get_consensus_strength Updater.confirm_ban_above
    0.0
    iex> Updater.get_consensus_strength Updater.refute_ban_under
    0.0
    iex> Updater.get_consensus_strength 1
    1.0
    iex> Updater.get_consensus_strength -1.0
    1.0
    iex> Updater.get_consensus_strength Updater.confirm_ban_above + ((1.0 - Updater.confirm_ban_above) / 2.0)
    0.5
  """
  def get_consensus_strength(score) when score <= @refute_ban_under,
      do: get_consensus_strength(abs(score), abs(@refute_ban_under))
  def get_consensus_strength(score) when score >= @confirm_ban_above,
      do: get_consensus_strength(score, @confirm_ban_above)
  def get_consensus_strength(abs_score, min_val) do
    Float.round (abs_score - min_val) * (1 / (1 - min_val)), 1
  end

  # Static accessors
  def min_nb_feedbacks_to_take_action, do: @min_nb_feedbacks_to_take_action
  def refute_ban_under, do: @refute_ban_under
  def confirm_ban_above, do: @confirm_ban_above
  def reputation_change_ranges, do: @reputation_change_ranges

  # --- Internal API ---

  def handle_call(:update, _, _) do
    Logger.info("[ModerationUpdater] Update")
    UserAction
    |> join(:inner, [a], uf in UserFeedback, uf.action_id == a.id)
    |> select([a, uf], %{
         id: a.id,
         user_id: a.user_id,
         type: a.type,
         context: a.context,
         entity: a.entity,
         entity_id: a.entity_id,
         nb_feedbacks: count(uf.id),
         feedbacks_sum: sum(uf.value)
       })
    |> having([_, uf], count(uf.id) >= @min_nb_feedbacks_to_take_action)
    |> group_by([a, _], a.id)
    |> Repo.all(log: false)
    |> log_update()
    |> Enum.map(&(Map.put(&1, :score, &1.feedbacks_sum / &1.nb_feedbacks)))
    |> Enum.map(&take_action/1)

    {:reply, :ok , :ok}
  end

  defp log_update(actions) do
    # Only log update when there is stuff to update
    if Enum.count(actions) == 0 do
      actions
    else
      Logger.info("[ModerationUpdater] Update")
      actions
    end
  end

  # Ignore actions with not enough feedbacks
  defp take_action(%{nb_feedbacks: nb_feedbacks}) when nb_feedbacks < @min_nb_feedbacks_to_take_action, do: nil

  # Confirm ban
  @action_create  UserAction.type(:create)
  @entity_comment UserAction.entity(:comment)
  defp take_action(action = %{score: score, type: @action_create, entity: @entity_comment})
  when score >= @confirm_ban_above do
    case Repo.get(Comment, action.entity_id) do
      nil -> Logger.warn("[ModerationUpdater] Can't find comment #{action.entity_id} for delete")
      comment ->
        Comments.admin_delete_comment comment, UserAction.moderation_context(action.context)
        params = %{target_user_id: comment.user_id, changes: %{"score" => score}}
        Recorder.admin_record!(:action_banned, :comment, params)

        # Record flags confirmations for flaggers to get reputation bonus
        flags = Repo.all from(f in Flag, where: f.action_id == ^action.id)
        Recorder.admin_record_all!(:confirmed_flag, :comment, Enum.map(flags, fn flag ->
          %{target_user_id: flag.source_user_id, changes: %{"score" => score}}
        end))
    end
  end

  # Abusive flags
  defp take_action(action = %{score: score, type: @action_create, entity: @entity_comment})
  when score <= @refute_ban_under do
    comment = Repo.get(Comment, action.entity_id)
    flags = Repo.all from(f in Flag, where: f.action_id == ^action.id)
    # Punish all users for abusive flags
    Recorder.admin_record_all!(:abused_flag, :comment, Enum.map(flags, fn flag ->
      %{target_user_id: flag.source_user_id, changes: %{"score" => score}}
    end))

    Repo.delete_all from(f in Flag, where: f.action_id == ^action.id)
    Repo.update(Ecto.Changeset.change(comment, is_reported: false))

    # TODO Broadcast un-report
  end

  # Ignore moderation of regular actions (not supported yet) and scores without consensus
  defp take_action(_), do: nil
end