defmodule CaptainFactGraphql.Resolvers.Statistics do

  @moduledoc """
  Absinthe solver for community insights and statistics
  """

  alias DB.Statistics

  alias Kaur.Result

  @doc """
  Solvers for statistics
  """
  @spec get(any, any) :: Result.result_tuple
  def get(root, args) do
    ok_tuple_map = %{
      user_count: Task.async(fn -> user_count(root, args) end),
      comment_count: Task.async(fn -> comment_count(root, args) end),
      statement_count: Task.async(fn -> statement_count(root, args) end),
      source_count: Task.async(fn -> source_count(root, args) end),
      leaderboard: Task.async(fn -> leaderboard(root, args) end),
      pending_invites_count: Task.async(fn -> pending_invites_count(root, args) end)
    }
    |> Enum.map(fn {k, v} -> {k, Task.await(v)} end)

    reducer = fn {k, v}, acc ->

      case acc do
        {:error, _} -> acc
        {:ok, acc} ->

          case v do
            {:ok, value} -> Map.put(acc, k, value) |> Result.ok
            {:error, _error} -> v
          end
      end
    end

    acc = Result.ok(%{})
    Enum.reduce(ok_tuple_map, acc, reducer)
  end

  @doc """
  returns
    `{:ok, user_count}`
    `{:error, "user count unprocessable"}`
  """
  @spec user_count(any, any)::({:ok, integer} | {:error, binary})
  def user_count(_root, _args) do
    Statistics.user_count
    |> Result.from_value
    |> Result.map_error(fn _ -> "user count unprocessable" end)
  end

  @doc """
  returns
    `{:ok, comment_count}`
    `{:error, "comment count unprocessable"}`
  """
  @spec comment_count(any, any)::({:ok, integer} | {:error, binary})
  def comment_count(_root, _args) do
    Statistics.comment_count
    |> Result.from_value
    |> Result.map_error(fn _ -> "comment count unprocessable" end)
  end

  @doc """
  returns
    `{:ok, statement_count}`
    `{:error, "statement count unprocessable"}`
  """
  @spec statement_count(any, any)::({:ok, integer} | {:error, binary})
  def statement_count(_root, _args) do
    Statistics.statement_count
    |> Result.from_value
    |> Result.map_error(fn _ -> "statement count unprocessable" end)
  end

  @doc """
  returns
    `{:ok, source_count}`
    `{:error, "source count unprocessable"}`
  """
  @spec source_count(any, any)::({:ok, integer} | {:error, binary})
  def source_count(_root, _args) do
    Statistics.source_count
    |> Result.from_value
    |> Result.map_error(fn _ -> "source count unprocessable" end)
  end

  @doc """
  returns
    `{:ok, best_users}`
    `{:error, "leaderboard unaccessible"}
  """
  @spec leaderboard(any, any)::({:ok, list} | {:error, binary})
  def leaderboard(_root, _args) do
    Statistics.leaderboard
    |> Result.from_value
    |> Result.map_error(fn _ -> "leaderboard unaccessible" end)
  end

  @doc """
  returns
    `{:ok, pending_invites_count}`
    `{:error, "pending invites count unprocessable"}
  """
  @spec pending_invites_count(any, any)::({:ok, integer} | {:error, binary})
  def pending_invites_count(_root, _args) do
    Statistics.pending_invites_count
    |> Result.from_value
    |> Result.map_error(fn _ -> "pending_invites count unprocessable" end)
  end

end
