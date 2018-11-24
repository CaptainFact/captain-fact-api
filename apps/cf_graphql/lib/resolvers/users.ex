defmodule CF.GraphQL.Resolvers.Users do
  @moduledoc """
  Resolver for `DB.Schema.User`
  """

  alias Kaur.Result

  alias DB.Repo
  alias DB.Schema.User
  alias DB.Schema.UserAction
  alias DB.Query.Actions

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

  @doc """
  Resolve user actions history
  """
  def activity_log(user, %{offset: offset, limit: limit}, _) do
    UserAction
    |> Actions.by_user(user)
    |> Actions.matching_entities(@watched_entities)
    |> DB.Query.order_by_last_inserted_desc()
    |> Repo.paginate(page: offset, page_size: limit)
    |> Result.ok()
  end
end
