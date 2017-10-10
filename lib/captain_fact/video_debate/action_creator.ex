defmodule CaptainFact.VideoDebate.ActionCreator do
  alias CaptainFactWeb.{ Speaker, Statement }
  alias CaptainFact.Actions.UserAction


  @entity_statement UserAction.entity(:statement)
  @entity_speaker UserAction.entity(:speaker)


  # Generic action generator

  def action(user_id, video_id, entity, entity_id, type, changes \\ nil) do
    UserAction.changeset %UserAction{}, %{
      user_id: user_id,
      context: UserAction.video_debate_context(video_id),
      type: type,
      entity: entity,
      entity_id: entity_id,
      changes: changes
    }
  end

  # Create
  @action_create UserAction.type(:create)

  def action_create(user_id, video_id, statement = %Statement{id: id}),
  do: action(user_id, video_id, @entity_statement, id, @action_create, %{
    text: statement.text,
    time: statement.time,
    speaker_id: statement.speaker_id
  })

  def action_create(user_id, video_id, speaker = %Speaker{id: id}),
  do: action(user_id, video_id, @entity_speaker, id, @action_create, %{
    full_name: speaker.full_name,
    title: speaker.title
  })

  # Add
  @action_add UserAction.type(:add)

  def action_add(user_id, video_id, speaker = %Speaker{id: id}),
  do: action(user_id, video_id, @entity_speaker, id, @action_add, %{
    full_name: speaker.full_name,
    title: speaker.title
  })

  # Update
  @action_update UserAction.type(:update)

  def action_update(user_id, video_id, changeset = %{data: %Statement{id: id}}),
  do: action(user_id, video_id, @entity_statement, id, @action_update, changeset.changes)

  def action_update(user_id, video_id, changeset = %{data: %Speaker{id: id}}),
  do: action(user_id, video_id, @entity_speaker, id, @action_update, changeset.changes)

  # Remove
  @action_remove UserAction.type(:remove)

  def action_remove(user_id, video_id, %Speaker{id: id}),
  do: action(user_id, video_id, @entity_speaker, id, @action_remove)

  # Delete
  @action_delete UserAction.type(:delete)

  def action_delete(user_id, video_id, %Statement{id: id}),
  do: action(user_id, video_id, @entity_statement, id, @action_delete)

  def action_delete(user_id, video_id, %Speaker{id: id}),
  do: action(user_id, video_id, @entity_speaker, id, @action_delete)

  # Restore
  @action_restore UserAction.type(:restore)

  def action_restore(user_id, video_id, %Statement{id: id}),
  do: action(user_id, video_id, @entity_statement, id, @action_restore)

  def action_restore(user_id, video_id, %Speaker{id: id}),
  do: action(user_id, video_id, @entity_speaker, id, @action_restore)
end
