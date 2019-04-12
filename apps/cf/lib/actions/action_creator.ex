defmodule CF.Actions.ActionCreator do
  @moduledoc """
  Helpers to create `UserAction` from changesets or schemas.
  Actions created by functions in this module are supposed to
  match with `CF.Actions.Validator` checks.
  """

  alias DB.Schema.UserAction
  alias DB.Schema.Video
  alias DB.Schema.Speaker
  alias DB.Schema.Statement
  alias DB.Schema.Comment

  # Create

  def action_create(user_id, statement = %Statement{}) do
    action(
      user_id,
      :statement,
      :create,
      video_id: statement.video_id,
      statement_id: statement.id,
      changes: %{
        "text" => statement.text,
        "time" => statement.time,
        "speaker_id" => statement.speaker_id
      }
    )
  end

  def action_create(user_id, speaker = %Speaker{}) do
    action(
      user_id,
      :speaker,
      :create,
      speaker_id: speaker.id,
      changes: %{
        "full_name" => speaker.full_name,
        "title" => speaker.title
      }
    )
  end

  def action_create(user_id, video_id, comment = %Comment{}, source_url \\ nil) do
    action(
      user_id,
      :comment,
      :create,
      video_id: video_id,
      statement_id: comment.statement_id,
      comment_id: comment.id,
      changes: %{
        "text" => comment.text,
        "source" => source_url,
        "statement_id" => comment.statement_id,
        "reply_to_id" => comment.reply_to_id
      }
    )
  end

  # Add

  def action_add(user_id, video_id, speaker = %Speaker{}) do
    action(
      user_id,
      :speaker,
      :add,
      video_id: video_id,
      speaker_id: speaker.id
    )
  end

  def action_add(user_id, video = %Video{}) do
    action(
      user_id,
      :video,
      :add,
      video_id: video.id,
      changes: %{
        "url" => Video.build_url(video)
      }
    )
  end

  # Update

  def action_update(user_id, %{data: statement = %Statement{}, changes: changes}) do
    action(
      user_id,
      :statement,
      :update,
      video_id: statement.video_id,
      statement_id: statement.id,
      changes: changes
    )
  end

  def action_update(user_id, %{data: video = %Video{}, changes: changes}) do
    action(
      user_id,
      :video,
      :update,
      video_id: video.id,
      changes: changes
    )
  end

  def action_update(user_id, %{data: %Speaker{id: id}, changes: changes}, video_id) do
    action(user_id, :speaker, :update, speaker_id: id, video_id: video_id, changes: changes)
  end

  def action_update(user_id, %{data: %Speaker{id: id}, changes: changes}) do
    action(user_id, :speaker, :update, speaker_id: id, changes: changes)
  end

  def action_update(user_id, %{changes: changes}) do
    logged_changes = Map.take(changes, ~w(username name picture_url locale)a)
    action(user_id, :user, :update, logged_changes)
  end

  # Remove

  def action_remove(user_id, video_id, %Speaker{id: id}) do
    action(user_id, :speaker, :remove, video_id: video_id, speaker_id: id)
  end

  def action_remove(user_id, %Statement{id: id, video_id: video_id}) do
    action(user_id, :statement, :remove, video_id: video_id, statement_id: id)
  end

  # Delete

  def action_delete(user_id, video_id, comment = %Comment{}) do
    action(
      user_id,
      :comment,
      :delete,
      video_id: video_id,
      statement_id: comment.statement_id
    )
  end

  def action_admin_delete(video_id, comment = %Comment{}) do
    admin_action(
      :comment,
      :delete,
      video_id: video_id,
      statement_id: comment.statement_id
    )
  end

  # Restore

  def action_restore(user_id, %Statement{id: id, video_id: video_id}) do
    action(user_id, :statement, :restore, video_id: video_id, statement_id: id)
  end

  def action_restore(user_id, video_id, %Speaker{id: id}) do
    action(user_id, :speaker, :restore, video_id: video_id, speaker_id: id)
  end

  # Votes

  def action_vote(user_id, video_id, vote_type, comment = %Comment{})
      when vote_type in [:self_vote, :vote_up, :vote_down] do
    action(
      user_id,
      Comment.type(comment),
      vote_type,
      video_id: video_id,
      statement_id: comment.statement_id,
      comment_id: comment.id,
      target_user_id: comment.user_id
    )
  end

  def action_revert_vote(user_id, video_id, vote_type, comment = %Comment{})
      when vote_type in [:revert_vote_up, :revert_vote_down, :revert_self_vote] do
    action(
      user_id,
      Comment.type(comment),
      vote_type,
      video_id: video_id,
      statement_id: comment.statement_id,
      comment_id: comment.id,
      target_user_id: comment.user_id
    )
  end

  # Flag

  def action_flag(user_id, video_id, comment = %Comment{}) do
    action(
      user_id,
      Comment.type(comment),
      :flag,
      video_id: video_id,
      statement_id: comment.statement_id,
      comment_id: comment.id
    )
  end

  # Special actions

  def action_ban(comment = %Comment{}, ban_reason, changes)
      when ban_reason in [
             :action_banned_bad_language,
             :action_banned_spam,
             :action_banned_irrelevant,
             :action_banned_not_constructive
           ] do
    admin_action(
      Comment.type(comment),
      ban_reason,
      target_user_id: comment.user_id,
      changes: changes
    )
  end

  def action_email_confirmed(user_id) do
    admin_action(:user, :email_confirmed, target_user_id: user_id)
  end

  @doc """
  Generic action generator. You should always prefer using specific action
  creators like `action_create` or `action_delete`.
  """
  def action(user_id, entity, action_type, params \\ []) do
    UserAction.changeset(
      %UserAction{},
      Enum.into(params, %{
        user_id: user_id,
        type: action_type,
        entity: entity
      })
    )
  end

  @doc """
  Generic action generator. You should always prefer using specific action
  creators like `action_admin_delete`.
  """
  def admin_action(entity, action_type, params \\ []) do
    UserAction.changeset_admin(
      %UserAction{},
      Enum.into(params, %{
        type: action_type,
        entity: entity
      })
    )
  end
end
