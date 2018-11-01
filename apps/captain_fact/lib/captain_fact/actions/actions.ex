defmodule CaptainFact.Actions do
  @moduledoc """
  Functions to query and handle `UserAction`
  """

  import Ecto.Query

  alias DB.Schema.{User, UserAction}
  alias DB.Repo
  alias DB.Query.Actions, as: ActionsQuery

  @doc """
  Count all actions with `action_type` type for this entity
  max_age: max action oldness (in seconds)
  """
  @spec count_wildcard(%User{}, atom | integer, integer) :: non_neg_integer
  def count_wildcard(user, action_type, max_age \\ -1) do
    UserAction
    |> where([a], a.user_id == ^user_id(user))
    |> where([a], a.type == ^action_type)
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
    |> where([a], a.type == ^action_type)
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
    ActionsQuery.for_period(query, datetime_start, datetime_now)
  end

  # Utils
  defp user_id(%{id: id}), do: id
  defp user_id(id) when is_integer(id), do: id
end
