defmodule CaptainFact.Comment do
  use CaptainFact.Web, :model

  schema "comments" do
    field :text, :string
    field :approve, :boolean

    field :source_url, :string
    field :source_title, :string

    belongs_to :user, CaptainFact.User
    belongs_to :statement, CaptainFact.Statement
    timestamps()
  end

  @required_fields ~w(statement_id)a
  @optional_fields ~w(source_url source_title approve text)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_source_or_text()
    |> validate_length(:text, min: 1, max: 240)
    |> validate_format(:source_url, ~r/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/)
  end

  defp validate_source_or_text(changeset) do
    case get_field(changeset, :text) || get_field(changeset, :source_url) do
      nil ->
        changeset
        |> add_error(:text, "You must set at least a source or a text")
        |> add_error(:source_url, "You must set at least a source or a text")
      _ -> changeset
    end
  end
end
