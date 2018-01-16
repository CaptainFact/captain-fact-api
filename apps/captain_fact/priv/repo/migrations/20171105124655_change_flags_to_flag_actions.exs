defmodule CaptainFact.Repo.Migrations.ChangeFlagsToFlagActions do
  use Ecto.Migration
  alias CaptainFact.Repo


  @doc"""
  Flags used to point on entities, they will now point directly on actions

  [!] This will remove all old flags
  """
  def change do
    # Remove all entries and deprecated indexes
    Repo.delete_all(CaptainFact.Actions.Flag)
    drop unique_index(:flags, [:source_user_id, :entity, :entity_id])

    # Alter table
    alter table(:flags) do
      remove :entity
      remove :entity_id
      remove :target_user_id
      add :action_id, references(:users_actions, on_delete: :delete_all), null: false
    end

    # Create new unique index for user / action (1 flag per action max)
    create unique_index(:flags, [:source_user_id, :action_id], name: :user_flags_unique_index)
  end
end
