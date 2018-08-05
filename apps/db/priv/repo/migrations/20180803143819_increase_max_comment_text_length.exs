defmodule DB.Repo.Migrations.IncreaseMaxCommentTextLength do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      modify :text, :string, size: 512
    end
  end
end
