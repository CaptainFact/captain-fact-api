defmodule CF.Graphql.Resolvers.Statistics do
  @moduledoc """
  Absinthe solver for community insights and statistics
  """

  alias DB.Statistics

  alias Kaur.Result

  @doc """
  Get default statistic object
  """
  @spec default(any, any, any) :: Result.result_tuple()
  def default(_, _, _) do
    Result.ok(%{})
  end

  @doc """
  Solvers for statistics
  """
  @spec all_totals(any, any, any) :: Result.result_tuple()
  def all_totals(_, _, _) do
    Result.ok(Statistics.all_totals())
  end

  @doc """
  returns
    `{:ok, best_users}`
    `{:error, "leaderboard unaccessible"}
  """
  @spec leaderboard(any, any) :: {:ok, list} | {:error, binary}
  def leaderboard(_root, _args) do
    Statistics.leaderboard()
    |> Result.from_value()
    |> Result.map_error(fn _ -> "leaderboard unaccessible" end)
  end
end
