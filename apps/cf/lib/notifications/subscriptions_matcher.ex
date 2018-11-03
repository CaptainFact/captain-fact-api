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
  def match_action(action = %{entity: :comment, type: :create}) do
    Subscription
    |> where([s], s.comment_id == ^action.comment_id)
    |> or_where([s], s.statement_id == ^action.statement_id)
    |> or_where([s], s.video_id == ^action.video_id)
    |> Repo.all()
  end

  def match_action(action = %{entity: :statement, type: type, video_id: video_id})
      when type in [:update, :remove, :create] do
    Subscription
    |> where([s], s.scope in ^[:video, :statement])
    |> where([s], s.statement_id == ^action.statement_id or s.video_id == ^video_id)
    |> Repo.all()
  end

  def match_action(%{entity: :video, type: :update, video_id: video_id}) do
    Subscription
    |> where([s], s.scope == ^:video)
    |> where([s], s.video_id == ^video_id)
    |> Repo.all()
  end

  def match_action(%{entity: :speaker, type: type, video_id: video_id})
      when type in [:add, :remove] do
    Subscription
    |> where([s], s.scope == ^:video)
    |> where([s], s.video_id == ^video_id)
    |> Repo.all()
  end

  def match_action(_), do: []
end
