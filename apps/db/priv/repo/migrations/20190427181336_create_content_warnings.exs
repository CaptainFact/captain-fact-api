defmodule DB.Repo.Migrations.CreateContentWarnings do
  use Ecto.Migration

  def up do
    DB.Type.ContentWarningSeverity.create_type()

    create table(:content_warnings) do
      add(:video_id, references(:videos), null: false)

      # Is it a success message (eg. "Good verifications here") or a severe warning (eg. "Astroturf")
      add(:severity, :content_warning_severity, null: false)

      # Type will be defined in frontend for easier modifications
      add(:type, :string, null: false)

      # A custom message that users can set to explain why this warning exist
      add(:custom_message, :text, null: true, max: 4096)
    end
  end

  def down do
    drop(table(:content_warnings))
    DB.Type.ContentWarningSeverity.drop_type()
  end
end
