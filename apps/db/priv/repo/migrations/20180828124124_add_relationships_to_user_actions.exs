defmodule DB.Repo.Migrations.AddRelationshipsToUserActions do
  @moduledoc """
  Add real relationships and migrate existing actions.

  You must ensure that:
    - All actions on statements, comments and facts have a context
    - For all statement actions, entity must still exist.
    - Ensure all users actions have a nil `entity_id`
    - Ensure all users actions have a nil `context`
    - Ensure there is no action in Moderation context
  """

  use Ecto.Migration
  import Ecto.Changeset, only: [change: 1, change: 2]
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.UserAction
  alias DB.Schema.Video
  alias DB.Schema.Comment
  alias DB.Schema.Speaker

  def up do
    # Remove actions that cannot be migrated
    remove_non_migrable_actions()

    # Add relationships columns
    alter table(:users_actions) do
      add(:statement_id, references(:statements, on_delete: :delete_all))
      add(:comment_id, references(:comments, on_delete: :delete_all))
      add(:speaker_id, references(:speakers, on_delete: :delete_all))
      add(:video_id, references(:videos, on_delete: :delete_all))
    end

    # Create indexes for videos and statements actions
    create(index(:users_actions, [:video_id]))
    create(index(:users_actions, [:statement_id]))

    # Apply previous alter table
    flush()

    # Migrate all existing actions
    UserAction
    |> Repo.all()
    |> Enum.map(&changeset_migrate_action/1)
    |> Enum.map(&Repo.update/1)

    # Remove deprecated `context` and `entity_id` columns
    alter table(:users_actions) do
      remove :context
      remove :entity_id
    end
  end

  def down do
    # Re-add deprecated `context` and `entity_id` columns
    alter table(:users_actions) do
      add(:context, :string, null: true)
      add(:entity_id, :integer, null: true)
    end

    # Create index on context
    create(index(:users_actions, [:context]))

    # Apply previous alter table
    flush()

    # Migrate all existing actions
    UserAction
    |> Repo.all()
    |> Enum.map(&revert_changeset_migrate_action/1)
    |> Enum.map(&(Repo.update(&1, log: false)))

    # Remove relationships columns
    alter table(:users_actions) do
      remove :video_id
      remove :statement_id
      remove :comment_id
      remove :speaker_id
    end
  end

  # ---- Private ----

  @video UserAction.entity(:video)
  @speaker UserAction.entity(:speaker)
  @statement UserAction.entity(:statement)
  @comment UserAction.entity(:comment)
  @fact UserAction.entity(:fact)

  defp remove_non_migrable_actions() do
    # Delete all actions made on deleted speakers
    nb_actions_speakers =
      UserAction
      |> where([a], a.entity == @speaker)
      |> join(:left, [a], s in Speaker, a.entity_id == s.id)
      |> where([a, s], is_nil(s.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(&Repo.delete/1)
      |> Enum.count()

    # Delete all actions made on deleted videos
    nb_actions_videos =
      UserAction
      |> where([a], like(a.context, "VD:%"))
      |> join(:left, [a], v in Video, v.id == fragment("CAST(substring(u0.context from 4) AS INTEGER)"))
      |> where([a, v], is_nil(v.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(&Repo.delete/1)
      |> Enum.count()

    # Delete all actions made on delete comments
    nb_actions_comments =
      UserAction
      |> where([a], a.entity == @comment or a.entity == @fact)
      |> join(:left, [a], c in Comment, a.entity_id == c.id)
      |> where([a, c], is_nil(c.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(&Repo.delete/1)
      |> Enum.count()

    total = nb_actions_speakers + nb_actions_videos + nb_actions_comments
    IO.puts("Deleted #{total} non migrable actions")
  end

  # --  Changeset to migrate existing actions to new model --

  defp changeset_migrate_action(action = %UserAction{entity: @video}) do
    change(action, video_id: action.entity_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: @speaker}) do
    video_id = get_video_id_from_context(action.context)
    change(action, video_id: video_id, speaker_id: action.entity_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: @statement}) do
    video_id = get_video_id_from_context(action.context)
    change(action, video_id: video_id, statement_id: action.entity_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: entity})
       when entity in [@comment, @fact] do
    comment = Repo.get(Comment, action.entity_id, log: false)

    change(
      action,
      video_id: get_video_id_from_context(action.context),
      comment_id: comment && comment.id,
      statement_id: comment && comment.statement_id
    )
  end

  # Ignore action by creating an empty changeset
  defp changeset_migrate_action(action),
    do: change(action)

  defp get_video_id_from_context(nil),
    do: nil

  defp get_video_id_from_context("VD:" <> video_id),
    do: String.to_integer(video_id)

  defp get_video_id_from_context("MD:VD:" <> video_id),
    do: String.to_integer(video_id)

  # -- Changeset to rollback existing actions to their old model --

  defp revert_changeset_migrate_action(action = %UserAction{entity: @video}) do
    change(action, context: "VD:#{action.video_id}", entity_id: action.video_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: @speaker}) do
    context = get_context_from_video_id(action.video_id)
    change(action, context: context, entity_id: action.speaker_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: @statement}) do
    context = get_context_from_video_id(action.video_id)
    change(action, context: context, entity_id: action.statement_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: entity})
       when entity in [@comment, @fact] do
    context = get_context_from_video_id(action.video_id)
    change(action, context: context, entity_id: action.comment_id)
  end

  # Ignore action by creating an empty changeset
  defp revert_changeset_migrate_action(action),
    do: change(action)

  defp get_context_from_video_id(id) when id in ["", nil],
    do: nil

  defp get_context_from_video_id(video_id),
    do: "VD:#{video_id}"
end
