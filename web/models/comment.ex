defmodule CaptainFact.Comment do
  use CaptainFact.Web, :model

  schema "comments" do
    belongs_to :user, CaptainFact.User
    belongs_to :statement, CaptainFact.Statement

    field :text, :string
    field :approve, :boolean

    field :source_url, :string
    field :source_title, :string
    belongs_to :media, CaptainFact.Media
    timestamps()
  end

  @required_fields ~w(statement_id)a
  @optional_fields ~w(source_url approve text)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    # TODO Custom validator : must have either source or comment
  end
end
