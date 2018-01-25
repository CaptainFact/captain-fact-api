defmodule DB.Repo.Migrations.DeleteVideoDebateAction do
  use Ecto.Migration

  def change do
    drop table(:video_debate_actions)
  end
end
