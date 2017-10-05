defmodule CaptainFact.Comments.Vote do
  use CaptainFactWeb, :model

  alias CaptainFactWeb.Statement
  alias CaptainFact.Comments.Comment


  @primary_key false
  schema "votes" do
    belongs_to :user, CaptainFact.Accounts.User, primary_key: true
    belongs_to :comment, CaptainFact.Comments.Comment, primary_key: true

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

  def vote_type(user, entity, value) do
    cond do
      user.id == entity.user_id -> :self_vote
      value >= 0 -> :vote_up
      true -> :vote_down
    end
  end

  @required_fields ~w(value comment_id)a #TODO user_id ?

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:value, [-1, 1])
  end
end
