defmodule DB.Schema.Comment do
  @moduledoc """
  Represent a user comment that can be linked to a source
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias DB.Schema.{Comment, User, Statement, Source}

  @max_length 512

  schema "comments" do
    field(:text, :string)
    field(:approve, :boolean)
    field(:is_reported, :boolean, default: false)

    field(:score, :integer, virtual: true, default: 0)

    belongs_to(:source, Source)
    belongs_to(:user, User)
    belongs_to(:statement, Statement)
    belongs_to(:reply_to, Comment)
    timestamps()
  end

  def full(query, only_facts \\ false) do
    query
    |> join(:inner, [c], s in assoc(c, :statement))
    |> join(:left, [c, _], u in assoc(c, :user))
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
      is_reported: c.is_reported,
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
        achievements: u.achievements,
        speaker_id: u.speaker_id
      }
    })
  end

  def with_source(query, true) do
    from(c in query, join: source in Source, on: [id: c.source_id])
  end

  def with_source(query, false) do
    from(c in query, left_join: source in Source, on: [id: c.source_id])
  end

  def with_statement(query) do
    from(c in query, preload: [:statement])
  end

  # Getters

  def max_length, do: @max_length

  # Changesets

  @required_fields ~w(statement_id user_id)a
  @optional_fields ~w(approve text reply_to_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> update_change(:text, &prepare_text/1)
    |> validate_required(@required_fields)
    |> validate_source_or_text()
    |> validate_text()
    |> validate_length(:text, min: 1, max: @max_length)
  end

  def prepare_text(str) do
    str = String.trim(str)
    if String.length(str) > 0, do: str, else: nil
  end

  defp validate_source_or_text(changeset) do
    source = get_field(changeset, :source)
    text = get_field(changeset, :text)
    has_source = (source && source.url && String.length(source.url) > 0) || false
    has_text = text || false

    if has_text || has_source do
      changeset
    else
      changeset
      |> add_error(:text, "You must set at least a source or a text")
      |> add_error(:source, "You must set at least a source or a text")
    end
  end

  @url_regex ~r/https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/
  defp validate_text(changeset) do
    text = get_field(changeset, :text)
    # Text cannot contains URLs
    if text && Regex.match?(@url_regex, text) do
      add_error(changeset, :text, "Cannot include URL. Use source field instead")
    else
      changeset
    end
  end

  defp filter_facts(query, false), do: query

  defp filter_facts(query, true),
    do: where(query, [c, _, _, _, _], not is_nil(c.source_id))
end
