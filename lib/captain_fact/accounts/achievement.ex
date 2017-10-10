defmodule CaptainFact.Accounts.Achievement do
  use Ecto.Schema
  import Ecto.Changeset
  alias CaptainFact.Accounts.Achievement


  schema "achievements" do
    field :rarity, :integer
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(%Achievement{} = achievement, attrs) do
    achievement
    |> cast(attrs, [:slug, :rarity])
    |> validate_required([:slug, :rarity])
  end
end
