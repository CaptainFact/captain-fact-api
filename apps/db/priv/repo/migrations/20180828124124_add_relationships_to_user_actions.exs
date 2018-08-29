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
  alias DB.Type.VideoHashId
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

      # TODO Make this a varchar(10)
      add(
        :video_hash_id,
        references(:videos, column: :hash_id, type: :string, on_delete: :delete_all)
      )
    end

    # Create indexes for videos and statements actions
    create(index(:users_actions, [:video_hash_id]))
    create(index(:users_actions, [:statement_id]))

    # Apply previous alter table
    flush()

    # Migrate all existing actions
    UserAction
    |> Repo.all()
    |> Enum.map(&changeset_migrate_action/1)
    |> Enum.map(&Repo.update/1)

    # Remove deprecated `context` and `entity_id` columns
    # alter table(:user_actions) do
    #   remove :context
    #   remove :entity_id
    # end
  end

  def down do
    # Re-add deprecated `context` and `entity_id` columns
    # alter table(:users_actions) do
    #   add(:context, :string, null: true)
    #   add(:entity_id, :integer, null: true)
    # end

    # Create index on context
    # create(index(:users_actions, [:context]))

    # Apply previous alter table
    # flush()

    # Migrate all existing actions
    UserAction
    |> Repo.all()
    |> Enum.map(&revert_changeset_migrate_action/1)
    |> Enum.map(&Repo.update/1)

    # Remove relationships columns
    alter table(:users_actions) do
      remove :video_hash_id
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

    nb_actions_videos =
      UserAction
      |> where([a], like(a.context, "VD:%"))
      |> join(:left, [a], v in Video, v.id == fragment("CAST(substring(u0.context from 4) AS INTEGER)"))
      |> where([a, v], is_nil(v.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(&Repo.delete/1)
      |> Enum.count()

    total = nb_actions_speakers + nb_actions_videos
    IO.puts("Deleted #{total} non migrable actions")
  end

  # --  Changeset to migrate existing actions to new model --

  defp changeset_migrate_action(action = %UserAction{entity: @video}) do
    video_hash_id = VideoHashId.encode(action.entity_id)
    change(action, video_hash_id: video_hash_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: @speaker}) do
    video_hash_id = get_video_hash_id_from_context(action.context)
    change(action, video_hash_id: video_hash_id, speaker_id: action.entity_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: @statement}) do
    video_hash_id = get_video_hash_id_from_context(action.context)
    change(action, video_hash_id: video_hash_id, statement_id: action.entity_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: entity})
       when entity in [@comment, @fact] do
    comment = Repo.get(Comment, action.entity_id, log: false)

    change(
      action,
      video_hash_id: get_video_hash_id_from_context(action.context),
      comment_id: comment && comment.id,
      statement_id: comment && comment.statement_id
    )
  end

  # Ignore action by creating an empty changeset
  defp changeset_migrate_action(action),
    do: change(action)

  defp get_video_hash_id_from_context(nil),
    do: nil

  defp get_video_hash_id_from_context("VD:" <> video_id),
    do: VideoHashId.encode(String.to_integer(video_id))

  defp get_video_hash_id_from_context("MD:VD:" <> video_id),
    do: VideoHashId.encode(String.to_integer(video_id))

  # -- Changeset to rollback existing actions to their old model --

  defp revert_changeset_migrate_action(action = %UserAction{entity: @video}) do
    video_id = VideoHashId.decode!(action.video_hash_id)
    context = "VD:#{video_id}"
    change(action, context: context, entity_id: video_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: @speaker}) do
    context = get_context_from_video_hash_id(action.video_hash_id)
    change(action, context: context, entity_id: action.speaker_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: @statement}) do
    context = get_context_from_video_hash_id(action.video_hash_id)
    change(action, context: context, entity_id: action.statement_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: entity})
       when entity in [@comment, @fact] do
    context = get_context_from_video_hash_id(action.video_hash_id)
    change(action, context: context, entity_id: entity.comment_id)
  end

  # Ignore action by creating an empty changeset
  defp revert_changeset_migrate_action(action),
    do: change(action)

  defp get_context_from_video_hash_id(hash_id) when hash_id in ["", nil],
    do: nil

  defp get_context_from_video_hash_id(video_hash_id),
    do: "VD:#{VideoHashId.decode!(video_hash_id)}"
end
