defmodule CaptainFact.Comments.Comment do
  use Ecto.Schema
  import Ecto.{Changeset, Query} # TODO move queries to comments

  alias CaptainFact.Accounts.User
  alias CaptainFact.Speakers.Statement
  alias CaptainFact.Sources.Source
  alias CaptainFact.Comments.Comment

  schema "comments" do
    field :text, :string
    field :approve, :boolean
    field :is_reported, :boolean, default: false

    field :score, :integer, virtual: true, default: 0

    belongs_to :source, Source
    belongs_to :user, User
    belongs_to :statement, Statement
    belongs_to :reply_to, Comment
    timestamps()
  end

  def full(query, only_facts \\ false) do
    query
    |> join(:inner, [c], s in assoc(c, :statement))
    |> join(:inner, [c, _], u in assoc(c, :user))
    |> join(:left, [c, _, _], source in assoc(c, :source))
    |> join(:left, [c, _, _, _], v in fragment("
        SELECT sum(value) AS score, comment_id
        FROM   votes
        GROUP BY comment_id
       "), v.comment_id == c.id)
    |> filter_facts(only_facts)
    |> select([c, s, u, source, v], %{
        id: c.id,
        reply_to_id: c.reply_to_id,
        approve: c.approve,
        source: source,
        statement_id: c.statement_id,
        text: c.text,
        inserted_at: c.inserted_at,
        updated_at: c.updated_at,
        score: v.score,
        user: %{
          id: u.id,
          name: u.name,
          username: u.username,
          reputation: u.reputation,
          inserted_at: u.inserted_at,
          picture_url: u.picture_url,
          achievements: u.achievements
        }
      })
  end

  def with_source(query, true) do
    from c in query, join: source in Source, on: [id: c.source_id]
  end

  def with_source(query, false) do
    from c in query, left_join: source in Source, on: [id: c.source_id]
  end

  @required_fields ~w(statement_id user_id)a
  @optional_fields ~w(approve text reply_to_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> cast_assoc(:source)
    |> format_text()
    |> put_source()
    |> validate_required(@required_fields)
    |> validate_source_or_text()
    |> validate_length(:text, min: 1, max: 240)
  end

  defp format_text(struct = %{changes: %{text: text}}) do
    put_change(struct, :text, String.trim(text))
  end
  defp format_text(struct), do: struct

  defp put_source(struct = %{changes: %{source: %{changes: %{url: url}}}}) do
    case CaptainFact.Repo.get_by(CaptainFact.Sources.Source, url: url) do
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

  defp filter_facts(query, false), do: query
  defp filter_facts(query, true),
    do: where(query, [c, _, _, _, _], not is_nil(c.source_id))
end
