defmodule DB.Repo.Migrations.AddHashIdToVideos do
  use Ecto.Migration
  import Ecto.Query
  alias DB.Schema.Video

  def up do
    alter table(:videos) do
      # A size of 10 allows us to go up to 100_000_000_000_000 videos
      add(:hash_id, :string, size: 10)
    end

    # Create unique index on hash_id
    create(unique_index(:videos, [:hash_id]))

    # Flush pending migrations to ensure column is created
    flush()

    # Update all existing videos with their hashIds
    Video
    |> DB.Repo.all()
    |> Enum.map(&Video.changeset_generate_hash_id/1)
    |> Enum.map(&DB.Repo.update/1)
  end

  def down do
    alter table(:videos) do
      remove(:hash_id)
    end
  end
end
