defmodule CaptainFact.Comment do
  use CaptainFact.Web, :model

  schema "comments" do
    field :text, :string
    field :approve, :boolean

    belongs_to :source, CaptainFact.Source
    belongs_to :user, CaptainFact.User
    belongs_to :statement, CaptainFact.Statement
    timestamps()
  end

  @required_fields ~w(statement_id)a
  @optional_fields ~w(approve text)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:source)
    |> put_source()
    |> validate_required(@required_fields)
    |> validate_source_or_text()
    |> validate_length(:text, min: 1, max: 240)
  end

  defp put_source(struct = %{changes: %{source: %{changes: %{url: url}}}}) do
    case CaptainFact.Repo.get_by(CaptainFact.Source, url: url) do
      nil -> struct
      source -> put_assoc(struct, :source, source)
    end
  end

  defp put_source(struct), do: struct

  defp validate_source_or_text(changeset) do
    source = get_field(changeset, :source)
    text = get_field(changeset, :text)
    has_source = (source && source.url && String.length(source.url)) || false
    has_text = (text && String.length(text)) || false
    case has_text || has_source do
      false ->
        changeset
        |> add_error(:text, "You must set at least a source or a text")
        |> add_error(:source, "You must set at least a source or a text")
      _ -> changeset
    end
  end
end
