defmodule CaptainFact.Actions.ActionCreator do
  @moduledoc """
  Helpers to create `UserAction` from changesets or schemas.
  Actions created by functions in this module are supposed to
  match with `CaptainFact.Actions.Validator` checks.
  """

  alias DB.Type.VideoHashId
  alias DB.Schema.UserAction
  alias DB.Schema.Speaker
  alias DB.Schema.Statement

  @statement UserAction.entity(:statement)
  @speaker UserAction.entity(:speaker)

  # Create
  @create UserAction.type(:create)

  def action_create(user_id, statement = %Statement{}) do
    action(
      user_id,
      @statement,
      @create,
      video_id: statement.video_id,
      statement_id: statement.id,
      changes: %{
        text: statement.text,
        time: statement.time,
        speaker_id: statement.speaker_id
      }
    )
  end

  def action_create(user_id, speaker = %Speaker{}) do
    action(
      user_id,
      @speaker,
      @create,
      speaker_id: speaker.id,
      changes: %{
        full_name: speaker.full_name,
        title: speaker.title
      }
    )
  end

  # Add

  @add UserAction.type(:add)

  def action_add(user_id, video_id, speaker = %Speaker{}) do
    action(
      user_id,
      @speaker,
      @add,
      video_id: video_id,
      speaker_id: speaker.id,
      changes: %{
        full_name: speaker.full_name,
        title: speaker.title
      }
    )
  end

  # Update

  @update UserAction.type(:update)

  def action_update(user_id, %{data: statement = %Statement{}, changes: changes}) do
    action(
      user_id,
      @statement,
      @update,
      video_id: statement.video_id,
      statement_id: statement.id,
      changes: changes
    )
  end

  def action_update(user_id, %{data: %Speaker{id: id}, changes: changes}) do
    action(user_id, @speaker, @update, speaker_id: id, changes: changes)
  end

  # Remove

  @remove UserAction.type(:remove)

  def action_remove(user_id, video_id, %Speaker{id: id}) do
    action(user_id, @speaker, @remove, video_id: video_id, speaker_id: id)
  end

  def action_remove(user_id, %Statement{id: id, video_id: video_id}) do
    action(user_id, @statement, @remove, video_id: video_id, statement_id: id)
  end

  # Restore

  @restore UserAction.type(:restore)

  def action_restore(user_id, %Statement{id: id, video_id: video_id}) do
    action(user_id, @statement, @restore, video_id: video_id, statement_id: id)
  end

  def action_restore(user_id, video_id, %Speaker{id: id}) do
    action(user_id, @speaker, @restore, video_id: video_id, speaker_id: id)
  end

  # Generic action generator

  defp action(user_id, entity, action_type, params \\ []) do
    UserAction.changeset(%UserAction{}, %{
      user_id: user_id,
      type: action_type,
      entity: entity,
      video_hash_id: video_hash_id(params[:video_id]),
      statement_id: params[:statement_id],
      comment_id: params[:comment_id],
      speaker_id: params[:speaker_id],
      changes: params[:changes]
    })
  end

  # Helper to just put nil in `video_hash_id` if not set

  defp video_hash_id(nil), do: nil

  defp video_hash_id(video_id), do: VideoHashId.encode(video_id)
end
