defmodule DB.Query.Actions do
  @moduledoc """
  Functions to query and handle `UserAction`
  """

  import Ecto.Query

  alias DB.Schema.User

  @doc """
  Return all action concerning user, which is actions he made + actions he was
  targeted by.
  """
  @spec about_user(Ecto.Queryable.t(), %User{}) :: Ecto.Queryable.t()
  def about_user(query, %User{id: id}) do
    query
    |> where([a], a.user_id == ^id)
    |> or_where([a], a.target_user_id == ^id)
  end

  @doc """
  Return all action made by user.
  """
  @spec by_user(Ecto.Queryable.t(), %User{}) :: Ecto.Queryable.t()
  def by_user(query, %User{id: id}) do
    where(query, [a], a.user_id == ^id)
  end

  @doc """
  Return all action targeting user.
  """
  @spec targeting_user(Ecto.Queryable.t(), %User{}) :: Ecto.Queryable.t()
  def targeting_user(query, %User{id: id}) do
    where(query, [a], a.target_user_id == ^id)
  end

  @doc """
  Filter given query on matching `types` only
  """
  @spec matching_types(Ecto.Queryable.t(), nonempty_list(integer)) :: Ecto.Queryable.t()
  def matching_types(query, types) do
    where(query, [a], a.type in ^types)
  end

  @doc """
  Filter given query on matching entity types
  """
  @spec matching_entities(Ecto.Queryable.t(), nonempty_list(integer)) :: Ecto.Queryable.t()
  def matching_entities(query, types) do
    where(query, [a], a.entity in ^types)
  end

  @doc """
  Filter given query to return only actions that occured between `date_start`
  and `date_end`.
  """
  @spec for_period(Ecto.Queryable.t(), NaiveDateTime.t(), NaiveDateTime.t()) :: Ecto.Queryable.t()
  def for_period(query, datetime_start, datetime_end) do
    query
    |> where([a], a.inserted_at >= ^datetime_start)
    |> where([a], a.inserted_at <= ^datetime_end)
  end
end
