defmodule DB.Statistics do
  alias DB.Schema.{
    Comment,
    InvitationRequest,
    User,
    Source,
    Statement
  }

  alias DB.Repo

  import Ecto.Query

  @doc """
  A shortcut to returns the amount of user in the database
  """
  @spec user_count() :: integer
  def user_count, do: Repo.aggregate(User, :count, :id)

  @doc """
  A shortcut to returns the amount of comment in the database
  """
  @spec comment_count() :: integer
  def comment_count, do: Repo.aggregate(Comment, :count, :id)

  @doc """
  A shortcut to returns the amount of statement in the database
  """
  @spec statement_count() :: integer
  def statement_count, do: Repo.aggregate(Statement, :count, :id)

  @doc """
  A shortcut to returns the amount of source in the database
  """
  @spec source_count() :: integer
  def source_count, do: Repo.aggregate(Source, :count, :id)

  @doc """
  returns the 20 most active users
  """
  @spec leaderboard() :: list(%User{})
  def leaderboard do
    from(
      u in User,
      order_by: [desc: u.reputation],
      limit: 20
    )
    |> Repo.all()
  end

  @doc """
  returns the amount of not yet treated invites
  """
  @spec pending_invites_count() :: integer
  def pending_invites_count do
    InvitationRequest
    |> where([i], i.invitation_sent == false and not is_nil(i.email))
    |> Repo.aggregate(:count, :id)
  end
end
