defmodule :"Elixir.DB.Repo.Migrations.Add-facebook-id-to-videos" do
  use Ecto.Migration

  def up do
    # Add new columns
    alter table(:videos) do
      add(:facebook_id, :string, null: true)
      add(:facebook_offset, :integer, null: false, default: 0)
    end

    # Create index
    create(unique_index(:videos, :facebook_id))
  end

  def down do
    # Remove columns
    alter table(:videos) do
      remove(:facebook_id)
      remove(:facebook_offset)
    end
  end
end
