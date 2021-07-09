defmodule :"Elixir.DB.Repo.Migrations.Add-reputation-to-user-actions" do
  use Ecto.Migration
  alias CF.Actions.ReputationChange

  require Logger

  def up do
    alter table("users_actions") do
      add(:author_reputation_change, :integer, null: false, default: 0)
      add(:target_reputation_change, :integer, null: false, default: 0)
    end

    # vote_down: {author_reputation_change: -1, target_reputation_change: -3}
    # ...etc
    Enum.each(ReputationChange.actions(), &update_for_actions_entry/1)
  end

  def down do
    alter table("users_actions") do
      remove(:author_reputation_change)
      remove(:target_reputation_change)
    end
  end

  defp update_for_actions_entry({action_type, {author_reputation_change, target_reputation_change}}) do
    execute """
      UPDATE users_actions
      SET author_reputation_change = #{author_reputation_change},
      target_reputation_change = #{target_reputation_change}
      WHERE type = #{dump_action_type!(action_type)}
    """
  end

  defp update_for_actions_entry({action_type, details}) when is_map(details) do
    Enum.each(details, fn {entity, {author_reputation_change, target_reputation_change}} ->
    execute """
      UPDATE users_actions
      SET author_reputation_change = #{author_reputation_change},
      target_reputation_change = #{target_reputation_change}
      WHERE type = #{dump_action_type!(action_type)}
      AND entity = #{dump_entity_type!(entity)}
    """
    end)
  end

  defp dump_action_type!(action_type) do
    {:ok, action_type_id} = DB.Type.UserActionType.dump(action_type)
    action_type_id
  end

  defp dump_entity_type!(entity) do
    {:ok, entity_id} = DB.Type.Entity.dump(entity)
    entity_id
  end
end
