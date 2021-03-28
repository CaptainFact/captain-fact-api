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
  def for_user(user, %{page: page, page_size: page_size, filter: filter}, %{
        context: %{user: loggedin_user}
      }) do
    if user.id !== loggedin_user.id do
      {:error, "unauthorized"}
    else
      {:ok, Notifications.all(user, page, page_size, filter)}
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
    |> select([n], n)
    |> DB.Repo.update_all([set: [seen_at: seen_at]], returning: true)
    |> elem(1)
    |> Result.ok()
  end

  @doc """
  Update the given subscription
  """
  def update_subscription(
        _,
        %{
          scope: scope,
          entity_id: entity_id,
          is_subscribed: is_subscribed
        } = params,
        %{context: %{user: loggedin_user}}
      ) do
    entity = load_entity(scope, entity_id)

    cond do
      is_nil(entity) ->
        {:error, "not_found"}

      is_subscribed ->
        Subscriptions.subscribe(loggedin_user, entity, params[:reason])

      true ->
        Subscriptions.unsubscribe(loggedin_user, entity)
    end
  end

  defp load_entity("comment", entity_id) do
    DB.Repo.get(DB.Schema.Comment, entity_id)
  end

  defp load_entity("statement", entity_id) do
    DB.Repo.get(DB.Schema.Statement, entity_id)
  end

  defp load_entity("video", entity_id) do
    DB.Repo.get(DB.Schema.Video, entity_id)
  end
end
