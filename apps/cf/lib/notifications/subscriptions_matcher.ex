defmodule CF.Notifications.SubscriptionsMatcher do
  @moduledoc """
  Matches actions with subscriptions. This module is how we know which user
  should be notified when a specific action is made.
  """

  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.Subscription
  alias DB.Schema.UserAction

  @doc """
  Takes an action, check for subscriptions, returns a list of `Subscription`
  watching this.

  In case multiple subscriptions match for the same user, only returns the more
  accurate one (in order, Comment - Statemement - Video).
  """
  @spec match_action(UserAction.t()) :: [Subscription.t()]
  def match_action(
        action = %{
          entity: :comment,
          type: :create,
          user_id: user_id,
          changes: %{"reply_to_id" => reply_to_id}
        }
      )
      when not is_nil(reply_to_id) do
    Subscription
    |> where([s], s.user_id != ^user_id and s.is_subscribed == true)
    |> where(
      [s],
      (s.comment_id == ^reply_to_id and s.scope == ^:comment) or
        (s.statement_id == ^action.statement_id and s.scope == ^:statement) or
        (s.video_id == ^action.video_id and s.scope == ^:video)
    )
    |> Repo.all()
    |> uniq_subscriptions()
  end

  def match_action(action = %{entity: :comment, type: :create, user_id: user_id}) do
    Subscription
    |> where([s], s.user_id != ^user_id and s.is_subscribed == true)
    |> where(
      [s],
      (s.statement_id == ^action.statement_id and s.scope == ^:statement) or
        (s.video_id == ^action.video_id and s.scope == ^:video)
    )
    |> Repo.all()
    |> uniq_subscriptions()
  end

  def match_action(action = %{entity: :statement, type: type, user_id: user_id})
      when type in [:update, :remove, :create] do
    Subscription
    |> where([s], s.user_id != ^user_id and s.is_subscribed == true)
    |> where(
      [s],
      (s.statement_id == ^action.statement_id and s.scope == ^:statement) or
        (s.video_id == ^action.video_id and s.scope == ^:video)
    )
    |> Repo.all()
    |> uniq_subscriptions()
  end

  def match_action(%{entity: :video, type: :update, video_id: video_id, user_id: user_id}) do
    Subscription
    |> where([s], s.user_id != ^user_id and s.is_subscribed == true)
    |> where([s], s.scope == ^:video)
    |> where([s], s.video_id == ^video_id)
    |> Repo.all()
    |> uniq_subscriptions()
  end

  def match_action(%{entity: :speaker, type: type, video_id: video_id, user_id: user_id})
      when type in [:add, :remove] do
    Subscription
    |> where([s], s.user_id != ^user_id and s.is_subscribed == true)
    |> where([s], s.scope == ^:video)
    |> where([s], s.video_id == ^video_id)
    |> Repo.all()
    |> uniq_subscriptions()
  end

  def match_action(_), do: []

  # Ensure we only return one subscription per user/entity.
  # Always returns the more precise subscription
  defp uniq_subscriptions(subscriptions) do
    subscriptions
    |> Enum.group_by(& &1.user_id)
    |> Enum.map(fn
      # Only one subscription, return it
      {_, [subscription | []]} ->
        subscription

      # Multiple subscriptions, let's pick the most precise one
      {_, user_subscriptions} ->
        Enum.max_by(user_subscriptions, &subscription_precision/1)
    end)
  end

  defp subscription_precision(%{video_id: nil}), do: 0
  defp subscription_precision(%{statement_id: nil}), do: 1
  defp subscription_precision(%{comment_id: nil}), do: 2
  defp subscription_precision(_), do: 3
end
