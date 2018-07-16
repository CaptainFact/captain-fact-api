defmodule CaptainFact.Actions do
  @moduledoc """
  Functions to query and handle `UserAction`
  """

  import Ecto.Query

  alias DB.Schema.User


  @doc """
  Return all action concerning user, which is actions he made + actions he was
  targeted by.
  """
  def query_about_user(query, %User{id: id}) do
    query
    |> where([a], a.user_id == ^id)
    |> where([a], a.target_user_id == ^id)
  end

  @doc """
  Filter given query on matching `types` only
  """
  def query_matching_types(query, types) do
    where(query, [a], a.type in ^types)
  end
end