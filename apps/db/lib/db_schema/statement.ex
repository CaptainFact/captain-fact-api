defmodule DB.Schema.Statement do
  @moduledoc """
  Ecto schema for `statements` table.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  schema "statements" do
    field(:text, :string)
    field(:time, :integer)
    field(:is_removed, :boolean, default: false)

    belongs_to(:video, DB.Schema.Video)
    belongs_to(:speaker, DB.Schema.Speaker)

    has_many(:comments, DB.Schema.Comment, on_delete: :delete_all)

    timestamps()
  end

  @required_fields ~w(text time video_id)a
  @optional_fields ~w(speaker_id)a

  # Define queries

  @doc """
  Select all statements and order them by id.

  ## Params

    * query: an Ecto query
    * filters: a list of tuples like {filter_name, value}.
      Valid filters:
        - commented: select all statements without comments if commented == false, otherwise select those with comments
        - speaker_id: speaker's integer ID
    * limit: Max number of videos to return
  """
  def query_list(query, filters \\ [], limit \\ nil) do
    query
    |> order_by([s], desc: s.id)
    |> filter_with(filters)
    |> limit_statement_query_list(limit)
  end

  # TODO: Not sure if it is used ...
  defp limit_statement_query_list(query, nil),
    do: query

  defp limit_statement_query_list(query, limit),
    do: limit(query, ^limit)

  defp filter_with(query, filters) do
    Enum.reduce(filters, query, fn
      {:commented, false}, query ->
        from(s in query, left_join: c in assoc(s, :comments), where: is_nil(c.statement_id))
      {:commented, true}, query ->
        from(s in query, left_join: c in assoc(s, :comments), where: not is_nil(c.statement_id))
      {:speaker_id, id}, query ->
        from(s in query, join: speaker in assoc(s, :speaker), where: speaker.id == ^id)
    end)
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:time, greater_than_or_equal_to: 0)
    |> validate_length(:text, min: 10, max: 255)
    |> cast_assoc(:speaker)
  end

  @doc """
  Builds a deletion changeset for `struct`
  """
  def changeset_remove(struct) do
    cast(struct, %{is_removed: true}, [:is_removed])
  end

  @doc """
  Builds a restore changeset for `struct`
  """
  def changeset_restore(struct) do
    cast(struct, %{is_removed: false}, [:is_removed])
  end
end
