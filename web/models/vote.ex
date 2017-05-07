defmodule CaptainFact.Vote do
  use CaptainFact.Web, :model

  alias CaptainFact.Statement
  alias CaptainFact.Comment


  @primary_key false
  schema "votes" do
    belongs_to :user, CaptainFact.User, primary_key: true
    belongs_to :comment, CaptainFact.Comment, primary_key: true

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
        false -> [value: "Can only be -1, 0 +1"]
      end  
    end
  end
end
