defmodule CF.GraphQL.Resolvers.Users do
  @moduledoc """
  Resolver for `DB.Schema.User`
  """

  import Ecto.Query

  alias Kaur.Result

  alias DB.Repo
  alias DB.Schema.User
  alias DB.Schema.UserAction

  @doc """
  Resolve a user by its id or username
  """
  def get(_, %{id: id}, _) do
    User
    |> Repo.get(id)
    |> Result.ok()
  end

  def get(_, %{username: username}, _) do
    User
    |> Repo.get_by(username: username)
    |> Result.ok()
  end

  @doc """
  Get logged in user
  """
  def get_logged_in(_, _, %{context: %{user: user}}) do
    {:ok, user}
  end

  @doc """
  Resolve main picture URL for `user`
  """
  def picture_url(user, _, _) do
    {:ok, DB.Type.UserPicture.url({user.picture_url, user}, :thumb)}
  end

  @doc """
  Resolve small picture URL for `user`
  """
  def mini_picture_url(user, _, _) do
    {:ok, DB.Type.UserPicture.url({user.picture_url, user}, :mini_thumb)}
  end

  @watched_entities ~w(video speaker statement comment fact)a
  @action_banned [
    :action_banned_bad_language,
    :action_banned_spam,
    :action_banned_irrelevant,
    :action_banned_not_constructive
  ]

  @doc """
  Resolve user actions history
  """
  def activity_log(user, %{offset: offset, limit: limit}, _) do
    UserAction
    |> where([a], a.user_id == ^user.id and a.entity in ^@watched_entities)
    |> or_where([a], a.target_user_id == ^user.id and a.type in ^@action_banned)
    |> DB.Query.order_by_last_inserted_desc()
    |> Repo.paginate(page: offset, page_size: limit)
    |> Result.ok()
  end

  @doc """
  Get videos added by this user
  """
  def videos_added(user, %{offset: offset, limit: limit}, _) do
    {:ok, CF.Videos.added_by_user(user, page: offset, page_size: limit)}
  end
end
