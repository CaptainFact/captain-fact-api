defmodule CF.Notifications do
  @moduledoc """
  Functions to create, fetch, and manipulate notifications.
  """

  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias DB.Schema.UserAction
  alias DB.Schema.Notification

  @doc """
  Get all notifications for user, last inserted first.
  Paginated with `page` + `limit`.
  """
  @spec all(User.t()) :: Scrivener.Page.t()
  def all(%User{id: user_id}, page \\ 1, page_size \\ 10) do
    Notification
    |> where([n], n.user_id == ^user_id)
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(page: page, page_size: page_size)
  end

  @doc """
  Insert a new notification in DB.
  """
  @spec create!(User.t(), UserAction.t(), atom()) ::
          {:ok, Notification.t()} | {:error, Ecto.Changeset.t()}
  def create!(%User{id: user_id}, %UserAction{id: action_id}, type) do
    %Notification{}
    |> Notification.changeset(%{user_id: user_id, action_id: action_id, type: type})
    |> Repo.insert()
  end

  @doc """
  Mark the given notification as seen. Ignored if notification has already been
  seen.
  """
  @spec mark_as_seen(Notification.t()) :: Notification.t()
  def mark_as_seen(notification = %Notification{seen_at: nil}) do
    notification
    |> Notification.changeset(%{seen_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def mark_as_seen(notification = %Notification{}),
    do: notification
end
