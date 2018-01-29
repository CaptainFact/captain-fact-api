defmodule CaptainFact.Jobs.ModerationUpdaterTest do
  use CaptainFact.DataCase
  import CaptainFact.TestUtils
  doctest CaptainFact.Jobs.ModerationUpdater

  alias DB.Schema.Comment
  alias DB.Schema.User
  alias DB.Schema.Flag
  alias DB.Schema.UserAction

  alias CaptainFact.Moderation
  alias CaptainFact.Jobs.ModerationUpdater


  @feedback_confirm 1
  @feedback_refute -1
  @feedback_neutral 0

  test "Report confirmed (score >= 0.66)" do
    {comment, action} = insert_reported_comment_with_action()
    generate_feedback(action, @feedback_confirm, ModerationUpdater.min_nb_feedbacks_to_take_action)
    ModerationUpdater.update()
    CaptainFact.Jobs.Reputation.update()

    assert_deleted comment
    # Lower action's source user reputation
    assert Repo.get!(User, action.user_id).reputation < action.user.reputation
    # Flaggers gain reputation
    flags = Repo.all from(f in Flag, where: f.action_id == ^action.id, preload: :source_user)
    Enum.map(flags, fn f ->
      assert Repo.get(User, f.source_user.id).reputation > f.source_user.reputation
    end)
  end

  test "Report refuted (if score <= -0.66)" do
    {comment, action} = insert_reported_comment_with_action()
    generate_feedback(action, @feedback_refute, ModerationUpdater.min_nb_feedbacks_to_take_action)
    flags = Repo.all from(f in Flag, where: f.action_id == ^action.id, preload: :source_user)
    ModerationUpdater.update()
    CaptainFact.Jobs.Reputation.update()

    refute_deleted comment
    # Un-report comment
    assert Repo.get!(Comment, comment.id).is_reported == false
    # Flags are cleared
    assert Enum.count(Repo.all(from(f in Flag, where: f.action_id == ^action.id))) == 0
    # Source user reputation stays the same
    assert Repo.get!(User, action.user_id).reputation == action.user.reputation
    # Flaggers loose reputation
    Enum.map(flags, fn f ->
      assert Repo.get(User, f.source_user.id).reputation < f.source_user.reputation
    end)
  end

  test "Not sure yet (if score between -0.66 and 0.66)" do
    {comment, action} = insert_reported_comment_with_action()
    generate_feedback(action, @feedback_neutral, ModerationUpdater.min_nb_feedbacks_to_take_action)
    ModerationUpdater.update()
    CaptainFact.Jobs.Reputation.update()

    refute_deleted comment
    # Stays reported
    assert Repo.get!(Comment, comment.id).is_reported == true
    # Doesn't clear flags
    assert Enum.count(Repo.all(from(f in Flag, where: f.action_id == ^action.id))) != 0
    # Source user reputation stays the same
    assert Repo.get!(User, action.user_id).reputation == action.user.reputation
  end

  test "reputation gain / loss is ponderated with the strength of the consensus" do
    {_, action} = insert_reported_comment_with_action()
    # Generate one neutral so consensus_strength should not be 1
    generate_feedback(action, @feedback_confirm, ModerationUpdater.min_nb_feedbacks_to_take_action)
    generate_feedback(action, @feedback_neutral, 1)

    ModerationUpdater.update()
    CaptainFact.Jobs.Reputation.update()

    min_change..max_change = ModerationUpdater.reputation_change_ranges[UserAction.type(:action_banned)]
    updated_reputation = Repo.get!(User, action.user_id).reputation
    abs_change = abs(updated_reputation - action.user.reputation)
    assert abs_change > abs(min_change)
    assert abs_change < abs(max_change)
  end

  defp insert_reported_comment_with_action() do
    comment = insert_reported_comment()
    action = Repo.get_by! UserAction,
      entity: UserAction.entity(:comment), type: UserAction.type(:create), entity_id: comment.id
    {comment, Repo.preload(action, :user)}
  end

  defp generate_feedback(action, feedback_type, num) do
    for _ <- 1..num do
      user = insert(:user, %{reputation: 10000})
      Moderation.feedback!(user, action.id, feedback_type)
    end
  end

  defp insert_reported_comment() do
    limit = CaptainFact.Moderation.nb_flags_report(UserAction.type(:create), UserAction.entity(:comment))
    comment = insert(:comment) |> with_action() |> flag(limit)
    CaptainFact.Jobs.Flags.update()

    # Reload comment
    comment =
      Comment
      |> preload([:user])
      |> Repo.get(comment.id)

    assert comment.is_reported == true
    comment
  end
end