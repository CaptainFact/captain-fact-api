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

  @doc """
  Get all subscriptions for user
  """
  @spec all(User.t()) :: [Subscription.t()]
  def all(%User{id: user_id}) do
    Subscription
    |> where([s], s.user_id == ^user_id)
    |> DB.Repo.all()
  end

  @doc """
  Subscribe to given entity changes.
  """
  @spec subscribe(User.t(), any(), DB.Type.SubscriptionReason.type()) ::
          {:ok, Subscription.t()} | {:error, any()}
  def subscribe(user, entity, reason \\ nil) do
    (load_subscription(user, entity) || Ecto.build_assoc(user, :subscriptions))
    |> Subscription.changeset_entity(entity, reason)
    |> DB.Repo.insert_or_update()
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
