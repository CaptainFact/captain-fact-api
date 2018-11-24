defmodule DB.Repo.Migrations.AddFileTypeToSource do
  use Ecto.Migration

  def change do
    alter table(:sources) do
      add(:file_mime_type, :string, null: true)
    end
  end
end
