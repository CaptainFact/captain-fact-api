defmodule CaptainFact.VideoDebateActionCreator do
  alias CaptainFact. { VideoDebateAction, Speaker, Statement }


  # Generic action generator

  def action(user_id, video_id, entity, entity_id, type, changes \\ nil) do
    VideoDebateAction.changeset %VideoDebateAction{}, %{
      user_id: user_id,
      video_id: video_id,
      entity: entity,
      entity_id: entity_id,
      type: type,
      changes: changes
    }
  end

  # Create

  def action_create(user_id, video_id, statement = %Statement{id: id}),
  do: action(user_id, video_id, "statement", id, "create", %{
    text: statement.text,
    time: statement.time,
    speaker_id: statement.speaker_id
  })

  def action_create(user_id, video_id, speaker = %Speaker{id: id}),
  do: action(user_id, video_id, "speaker", id, "create", %{
    full_name: speaker.full_name,
    title: speaker.title
  })

  # Add
  def action_add(user_id, video_id, speaker = %Speaker{id: id}),
  do: action(user_id, video_id, "speaker", id, "add", %{
    full_name: speaker.full_name,
    title: speaker.title
  })

  # Update

  def action_update(user_id, video_id, changeset = %{data: %Statement{id: id}}),
  do: action(user_id, video_id, "statement", id, "update", changeset.changes)

  def action_update(user_id, video_id, changeset = %{data: %Speaker{id: id}}),
  do: action(user_id, video_id, "speaker", id, "update", changeset.changes)

  # Remove
  def action_remove(user_id, video_id, %Speaker{id: id}),
  do: action(user_id, video_id, "speaker", id, "remove")

  # Delete
  def action_delete(user_id, video_id, %Statement{id: id}),
  do: action(user_id, video_id, "statement", id, "delete")

  def action_delete(user_id, video_id, %Speaker{id: id}),
  do: action(user_id, video_id, "speaker", id, "delete")

  # Restore
  def action_restore(user_id, video_id, %Statement{id: id}),
  do: action(user_id, video_id, "statement", id, "restore")

  def action_restore(user_id, video_id, %Speaker{id: id}),
  do: action(user_id, video_id, "speaker", id, "restore")
end
