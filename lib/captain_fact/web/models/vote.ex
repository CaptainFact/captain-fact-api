defmodule CaptainFact.Web.Vote do
  use CaptainFact.Web, :model

  alias CaptainFact.Web.Statement
  alias CaptainFact.Web.Comment


  @primary_key false
  schema "votes" do
    belongs_to :user, CaptainFact.Web.User, primary_key: true
    belongs_to :comment, CaptainFact.Web.Comment, primary_key: true

    field :value, :integer, null: false

    timestamps()
  end

  def user_votes(query, %{id: user_id}) do
    from v in query,
    where: v.user_id == ^user_id
  end

  def video_votes(query, %{id: video_id}) do
    from v in query,
    join: c in Comment, on: c.id == v.comment_id,
    join: s in Statement, on: c.statement_id == s.id,
    where: s.video_id == ^video_id
  end

  @doc """
  Get an atom describing the vote
  ## Examples
      iex> CaptainFact.Web.Vote.get_vote_type(%{source: nil}, nil, 0)
      nil
      iex> CaptainFact.Web.Vote.get_vote_type(%{source: "source"}, 0, 0)
      nil
      iex> CaptainFact.Web.Vote.get_vote_type(%{source: nil}, 0, 1)
      :comment_vote_up
      iex> CaptainFact.Web.Vote.get_vote_type(%{source: "source"}, 1, 0)
      :fact_vote_down
      iex> CaptainFact.Web.Vote.get_vote_type(%{source: nil}, -1, 1)
      :comment_vote_down_to_up
      iex> CaptainFact.Web.Vote.get_vote_type(%{source: "source"}, 1, -1)
      :fact_vote_up_to_down
  """
  def get_vote_type(_, nil, 0), do: nil
  def get_vote_type(_, base_value, base_value), do: nil
  def get_vote_type(comment, base_value, value) do
    (if comment.source_id, do: "fact_vote_", else: "comment_vote_")
    |> (&(&1 <> get_vote_direction(base_value, value))).()
    |> String.to_atom()
  end

  def get_vote_direction(base_value, value)
  when is_nil(base_value) or base_value == 0 or value == 0 do
    if value > (base_value || 0), do: "up", else: "down"
  end
  def get_vote_direction(base_value, value) when base_value < value, do: "down_to_up"
  def get_vote_direction(base_value, value) when base_value > value, do: "up_to_down"


  @required_fields ~w(value comment_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_vote_value()
  end

  defp validate_vote_value(changeset) do
    validate_change changeset, :value, fn :value, value ->
      case value in [-1, 0, 1] do
        true -> []
        false -> [value: "Can only be -1, 0 or +1"]
      end  
    end
  end
end
