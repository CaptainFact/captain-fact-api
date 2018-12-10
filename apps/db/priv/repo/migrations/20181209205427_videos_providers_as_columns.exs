defmodule DB.Repo.Migrations.VideosProvidersAsColumns do
  @moduledoc """
  This migration changes the `Videos` schema to go from a pair
  of {provider, provider_id} to a model where we have multiple  `{provider}_id`
  column. This will allow to store multiple sources for a single video, with
  different offsets to ensure they're all in sync.
  """

  use Ecto.Migration

  def up do
    # Add new columns
    alter table(:videos) do
      add(:youtube_id, :string, null: true, length: 11)
      add(:youtube_offset, :integer, null: false, default: 0)
    end

    flush()

    # Migrate existing videos - we only have YouTube right now
    Ecto.Adapters.SQL.query!(DB.Repo, """
    UPDATE videos SET youtube_id = provider_id;
    """)

    flush()

    # Create index
    create(unique_index(:videos, :youtube_id))

    # Remove columns
    alter table(:videos) do
      remove(:provider)
      remove(:provider_id)
    end
  end

  def down do
    # Restore old scheme
    alter table(:videos) do
      add(:provider, :string)
      add(:provider_id, :string)
    end

    flush()

    # Migrate existing videos
    Ecto.Adapters.SQL.query!(DB.Repo, """
    UPDATE videos SET provider_id = youtube_id, provider = 'youtube';
    """)

    flush()

    # Re-create index
    create(unique_index(:videos, [:provider, :provider_id]))

    # Remove columns
    alter table(:videos) do
      remove(:youtube_id)
      remove(:youtube_offset)
    end
  end
end
