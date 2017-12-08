defmodule CaptainFact.Repo.Migrations.AddNewsletterToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :newsletter, :boolean, null: false, default: true
      add :newsletter_subscription_token, :string, null: false, default: fragment("md5(random()::text)")
    end

    create unique_index(:users, :newsletter_subscription_token)
  end
end
