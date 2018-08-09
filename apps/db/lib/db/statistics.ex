defmodule DB.Statistics do
  import Ecto.Query

  alias DB.Schema.User
  alias DB.Repo

  @doc """
  A shortcut to returns the amount of user in the database
  """
  @spec all_totals() :: %{users: integer, comments: integer, statements: integer, sources: integer}
  def all_totals() do
    Repo
    |> Ecto.Adapters.SQL.query!("""
      SELECT  (select count(id) FROM users) as users, 
              (select count(id) FROM comments) as comments,
              (select count(id) FROM statements) as statements, 
              (select count(id) FROM sources) as sources
    """)
    |> (fn %Postgrex.Result{rows: [[users, comments, statements, sources]]} ->
          %{users: users, comments: comments, statements: statements, sources: sources}
        end).()
  end

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
end
