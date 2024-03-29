defmodule CF.Notifications.Subscriptions do
  @moduledoc """
  Handles subscriptions to actions, ensuring no duplicate is created in
  the process.
  """

  import Ecto.Query

  alias DB.Schema.Subscription
  alias DB.Schema.User
  alias DB.Schema.Video
  alias DB.Schema.Statement
  alias DB.Schema.Comment

  @type subscribable_entities :: Video.t() | Statement.t() | Comment.t()

  @doc """
  Get all subscriptions for user.
  """
  @spec all(User.t(), Keyword.t()) :: [Subscription.t()]
  def all(%User{id: user_id}, filters \\ []) do
    Subscription
    |> where([s], s.user_id == ^user_id)
    |> apply_filters(filters)
    |> DB.Repo.all()
  end

  @doc """
  Check if user is subscribed to the given entity.

  TODO: When migrating to Ecto 3, there is now a `DB.Repo.exists?` function that we can use
  """
  def is_subscribed(%User{id: user_id}, %Video{id: video_id}) do
    Subscription
    |> select([:id, :is_subscribed])
    |> where([s], s.scope == ^:video)
    |> where([s], s.user_id == ^user_id)
    |> where([s], s.video_id == ^video_id)
    |> DB.Repo.one()
    |> case do
      nil ->
        false

      %{is_subscribed: is_subscribed} ->
        is_subscribed
    end
  end

  @doc """
  Subscribe to given entity changes.
  """
  @spec subscribe(User.t(), subscribable_entities(), DB.Type.SubscriptionReason.type()) ::
          {:ok, Subscription.t()} | {:error, any()}
  def subscribe(user, entity, reason \\ nil) do
    (load_subscription(user, entity) || Ecto.build_assoc(user, :subscriptions))
    |> Subscription.changeset_entity(entity, reason)
    |> DB.Repo.insert_or_update()
  end

  @doc """
  Unsubscribe from given entity changes.
  """
  @spec unsubscribe(User.t(), subscribable_entities()) :: {:ok, Subscription.t()} | nil
  def unsubscribe(user, entity) do
    user
    |> load_subscription(entity)
    |> case do
      nil ->
        {:error, "not_found"}

      subscription ->
        DB.Repo.update(Subscription.changeset_subscribed(subscription, false))
    end
  end

  # Apply subscriptions filters on query
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn {filter_name, value}, query ->
      case filter_name do
        :scopes ->
          where(query, [s], s.scope in ^value)

        :is_subscribed ->
          where(query, [s], s.is_subscribed == ^value)

        :video_id ->
          where(query, [s], s.video_id == ^value)

        _ ->
          query
      end
    end)
  end

  # Load an existing subscription for given user / entity.
  # Returns `nil` if it doesn't exist.
  defp load_subscription(user, %Comment{id: id}) do
    DB.Repo.get_by(Subscription, user_id: user.id, comment_id: id, scope: :comment)
  end

  defp load_subscription(user, %Statement{id: id}) do
    DB.Repo.get_by(Subscription, user_id: user.id, statement_id: id, scope: :statement)
  end

  defp load_subscription(user, %Video{id: id}) do
    DB.Repo.get_by(Subscription, user_id: user.id, video_id: id, scope: :video)
  end
end
