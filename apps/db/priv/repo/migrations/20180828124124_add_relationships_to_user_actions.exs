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
  alias DB.Schema.Speaker
  alias DB.Schema.Statement
  alias DB.Schema.Comment

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
    nb_actions =
      UserAction
      |> Repo.all()
      |> Enum.map(&changeset_migrate_action/1)
      |> Enum.map(&Repo.update(&1, log: false))
      |> Enum.count()

    IO.puts("#{nb_actions} actions successfully migrated")
  end

  def down do
    # Un-migrate all existing actions
    UserAction
    |> Repo.all()
    |> Enum.map(&revert_changeset_migrate_action/1)
    |> Enum.map(&Repo.update(&1, log: false))

    # Remove relationships columns
    alter table(:users_actions) do
      remove(:video_id)
      remove(:statement_id)
      remove(:comment_id)
      remove(:speaker_id)
    end
  end

  # ---- Private ----

  defp remove_non_migrable_actions() do
    delete_without_log = &Repo.delete(&1, log: false)

    # Delete all actions made on deleted speakers
    nb_actions_speakers =
      UserAction
      |> where([a], a.entity == ^:speaker)
      |> join(:left, [a], s in Speaker, fragment("u0.entity_id") == s.id)
      |> where([a, s], is_nil(s.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(delete_without_log)
      |> Enum.count()

    # Delete all actions made on deleted videos
    nb_actions_videos =
      UserAction
      |> where([a], like(a.context, "VD:%"))
      |> join(
        :left,
        [a],
        v in Video,
        v.id == fragment("CAST(substring(u0.context from 4) AS INTEGER)")
      )
      |> where([a, v], is_nil(v.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(delete_without_log)
      |> Enum.count()

    nb_actions_videos_direct =
      UserAction
      |> where([a], a.entity == ^:video)
      |> join(:left, [a], v in Video, fragment("u0.entity_id") == v.id)
      |> where([a, v], is_nil(v.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(delete_without_log)
      |> Enum.count()

    # Delete all actions made on delete comments
    nb_actions_comments =
      UserAction
      |> where([a], a.entity == ^:comment or a.entity == ^:fact)
      |> join(:left, [a], c in Comment, fragment("u0.entity_id") == c.id)
      |> where([a, c], is_nil(c.id))
      |> select([:id])
      |> Repo.all()
      |> Enum.map(delete_without_log)
      |> Enum.count()

    IO.puts("Deleted #{nb_actions_speakers} speakers non migrable actions")
    IO.puts("Deleted #{nb_actions_videos + nb_actions_videos_direct} videos non migrable actions")
    IO.puts("Deleted #{nb_actions_comments} comments non migrable actions")
  end

  # --  Changeset to migrate existing actions to new model --

  defp changeset_migrate_action(action = %UserAction{entity: :video}) do
    base_update = [video_id: action.entity_id]

    full_update =
      if action.changes do
        base_update
      else
        video = Repo.get!(Video, action.entity_id)
        [{:changes, %{"url" => Video.build_url(video)}} | base_update]
      end

    change(action, full_update)
  end

  defp changeset_migrate_action(action = %UserAction{type: :add, entity: :speaker}) do
    video_id = get_video_id_from_context(action.context)
    change(action, video_id: video_id, speaker_id: action.entity_id, changes: nil)
  end

  defp changeset_migrate_action(action = %UserAction{entity: :speaker}) do
    video_id = get_video_id_from_context(action.context)
    change(action, video_id: video_id, speaker_id: action.entity_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: :statement}) do
    video_id = get_video_id_from_context(action.context)
    change(action, video_id: video_id, statement_id: action.entity_id)
  end

  defp changeset_migrate_action(action = %UserAction{entity: entity, context: context})
       when entity in [:comment, :fact] do
    comment = Repo.get(Comment, action.entity_id, log: false)

    change(
      action,
      video_id: get_video_id_from_context(context) || get_comment_video_id!(comment),
      comment_id: comment && comment.id,
      statement_id: comment && comment.statement_id
    )
  end

  # Ignore action by creating an empty changeset
  defp changeset_migrate_action(action),
    do: change(action)

  defp get_comment_video_id!(nil),
    do: nil

  defp get_comment_video_id!(comment) do
    Statement
    |> select([s], s.video_id)
    |> DB.Repo.get!(comment.statement_id)
  end

  defp get_video_id_from_context(nil),
    do: nil

  defp get_video_id_from_context("VD:" <> video_id),
    do: String.to_integer(video_id)

  defp get_video_id_from_context("MD:VD:" <> video_id),
    do: String.to_integer(video_id)

  # -- Changeset to rollback existing actions to their old model --

  defp revert_changeset_migrate_action(action = %UserAction{entity: :video}) do
    change(action, context: "VD:#{action.video_id}", entity_id: action.video_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: :speaker}) do
    context = get_context_from_video_id(action.video_id)
    change(action, context: context, entity_id: action.speaker_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: :statement}) do
    context = get_context_from_video_id(action.video_id)
    change(action, context: context, entity_id: action.statement_id)
  end

  defp revert_changeset_migrate_action(action = %UserAction{entity: entity})
       when entity in [:comment, :fact] do
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
