defmodule CaptainFact.Comment do
  use CaptainFact.Web, :model

  schema "comments" do
    field :text, :string
    field :approve, :boolean

    field :source_url, :string
    field :source_title, :string

    belongs_to :user, CaptainFact.User
    belongs_to :statement, CaptainFact.Statement
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
    |> validate_source_or_text()
    |> validate_length(:text, min: 1, max: 240)
    |> validate_format(:source_url, ~r/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/)
  end

  def validate_source_or_text(%{changes: %{text: _text}} = changeset), do: changeset
  def validate_source_or_text(%{changes: %{source_url: _source_url}} = changeset), do: changeset
  def validate_source_or_text(changeset) do
    changeset
    |> add_error(:text, "You must set at least a source or a text")
    |> add_error(:source_url, "You must set at least a source or a text")
  end
end
