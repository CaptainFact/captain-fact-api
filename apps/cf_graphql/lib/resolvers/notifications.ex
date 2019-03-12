defmodule CF.Graphql.Resolvers.Notifications do
  @moduledoc """
  Resolver for `DB.Schema.User`
  """

  import Ecto.Query

  alias Kaur.Result

  alias DB.Schema.Notification
  alias CF.Notifications
  alias CF.Notifications.Subscriptions

  @doc """
  User notifications, only if authenticated
  """
  def for_user(user, %{page: page, page_size: page_size}, %{context: %{user: loggedin_user}}) do
    if user.id !== loggedin_user.id do
      {:error, "unauthorized"}
    else
      {:ok, Notifications.all(user, page, page_size)}
    end
  end

  @doc """
  User notifications, only if authenticated
  """
  def subscriptions(user, params, %{context: %{user: loggedin_user}}) do
    if user.id !== loggedin_user.id do
      {:error, "unauthorized"}
    else
      {:ok, Subscriptions.all(user, Map.to_list(params))}
    end
  end

  @doc """
  Update notification
  """
  def update(_, %{ids: ids, seen: seen}, %{context: %{user: loggedin_user}}) do
    seen_at = if seen, do: DateTime.utc_now(), else: nil

    Notification
    |> where([n], n.id in ^ids)
    |> where([n], n.user_id == ^loggedin_user.id)
    |> DB.Repo.update_all([set: [seen_at: seen_at]], returning: true)
    |> elem(1)
    |> Result.ok()
  end
end
