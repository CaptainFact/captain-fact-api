defmodule DB.Schema.Vote do
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias DB.Schema.{User, Statement, Comment}

  @type vote_value :: -1 | 1

  @primary_key false
  schema "votes" do
    belongs_to(:user, User, primary_key: true)
    belongs_to(:comment, Comment, primary_key: true)

    field(:value, :integer, null: false)

    timestamps()
  end

  def user_votes(query, %{id: user_id}) do
    from(
      v in query,
      where: v.user_id == ^user_id
    )
  end

  @spec user_comment_vote(Ecto.Query.t(), User.t(), Comment.t()) :: Ecto.Query.t()
  def user_comment_vote(query \\ __MODULE__, user, comment) do
    from(
      v in query,
      where: v.user_id == ^user.id,
      where: v.comment_id == ^comment.id,
      select: v
    )
  end

  def video_votes(query, %{id: video_id}) do
    from(
      v in query,
      join: c in Comment,
      on: c.id == v.comment_id,
      join: s in Statement,
      on: c.statement_id == s.id,
      where: s.video_id == ^video_id
    )
  end

  def vote_type(user, entity, value) do
    cond do
      user.id == entity.user_id -> :self_vote
      value >= 0 -> :vote_up
      true -> :vote_down
    end
  end

  @required_fields ~w(user_id value comment_id)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:value, [-1, 1])
  end

  @spec changeset_new(User.t(), Comment.t(), vote_value()) :: Changeset.t()
  def changeset_new(user = %User{}, comment = %Comment{}, value) do
    user
    |> Ecto.build_assoc(:votes)
    |> changeset(%{comment_id: comment.id, value: value})
  end
end
