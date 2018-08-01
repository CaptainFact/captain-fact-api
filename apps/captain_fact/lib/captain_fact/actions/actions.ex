defmodule CaptainFact.Actions do
  @moduledoc """
  Functions to query and handle `UserAction`
  """

  import Ecto.Query

  alias DB.Schema.{User, UserAction}
  alias DB.Repo

  @doc """
  Return all action concerning user, which is actions he made + actions he was
  targeted by.
  """
  @spec query_about_user(Ecto.Queryable.t(), %User{}) :: Ecto.Queryable.t()
  def query_about_user(query, %User{id: id}) do
    query
    |> where([a], a.user_id == ^id)
    |> or_where([a], a.target_user_id == ^id)
  end

  @doc """
  Filter given query on matching `types` only
  """
  @spec query_matching_types(Ecto.Queryable.t(), nonempty_list(integer)) :: Ecto.Queryable.t()
  def query_matching_types(query, types) do
    where(query, [a], a.type in ^types)
  end

  @doc """
  Filter given query to return only actions that occured between `date_start`
  and `date_end`.
  """
  @spec query_period(Ecto.Queryable.t(), NaiveDateTime.t(), NaiveDateTime.t()) ::
          Ecto.Queryable.t()
  def query_period(query, datetime_start, datetime_end) do
    query
    |> where([a], a.inserted_at >= ^datetime_start)
    |> where([a], a.inserted_at <= ^datetime_end)
  end

  @doc """
  Count all actions with `action_type` type for this entity
  max_age: max action oldness (in seconds)
  """
  @spec count_wildcard(%User{}, atom | integer, integer) :: non_neg_integer
  def count_wildcard(user, action_type, max_age \\ -1) do
    UserAction
    |> where([a], a.user_id == ^user_id(user))
    |> where([a], a.type == ^UserAction.type(action_type))
    |> age_filter(max_age)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Count all actions with `action_type` type and matching `entity` for this entity
  max_age: max action oldness (in seconds)
  """
  @spec count(%User{}, atom | integer, atom | integer, integer) :: non_neg_integer
  def count(user, action_type, entity, max_age \\ -1) do
    UserAction
    |> where([a], a.user_id == ^user_id(user))
    |> where([a], a.type == ^UserAction.type(action_type))
    |> where([a], a.entity == ^UserAction.entity(entity))
    |> age_filter(max_age)
    |> Repo.aggregate(:count, :id)
  end

  # ---- Private methods ----

  defp age_filter(query, -1),
    do: query

  defp age_filter(query, age) do
    datetime_now = NaiveDateTime.utc_now()
    datetime_start = NaiveDateTime.add(datetime_now, -age)
    query_period(query, datetime_start, datetime_now)
  end

  # Utils
  defp user_id(%{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id
end
