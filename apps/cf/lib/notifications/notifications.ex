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
  @spec all(User.t(), integer(), integer(), :all | :seen | :unseen) :: Scrivener.Page.t()
  def all(%User{id: user_id}, page \\ 1, page_size \\ 10, filter \\ :all) do
    Notification
    |> where([n], n.user_id == ^user_id)
    |> add_filter(filter)
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
  Mark the given notification as seen or unseed.
  seen.
  """
  @spec mark_as_seen(Notification.t(), boolean()) :: Notification.t()
  def mark_as_seen(notification = %Notification{seen_at: nil}, true) do
    notification
    |> Notification.changeset(%{seen_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def mark_as_seen(notification = %Notification{seen_at: seen_at}, false)
      when not is_nil(seen_at) do
    notification
    |> Notification.changeset(%{seen_at: nil})
    |> Repo.update()
  end

  def mark_as_seen(notification, _),
    do: {:ok, notification}

  defp add_filter(query, :seen), do: where(query, [n], not is_nil(n.seen_at))
  defp add_filter(query, :unseen), do: where(query, [n], is_nil(n.seen_at))
  defp add_filter(query, :all), do: query
end
