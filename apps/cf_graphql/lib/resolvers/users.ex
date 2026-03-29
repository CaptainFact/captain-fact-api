defmodule CF.Graphql.Resolvers.Users do
  @moduledoc """
  Resolver for `DB.Schema.User`
  """

  import Ecto.Query

  alias CF.Moderation
  alias CF.Accounts.UserPermissions

  alias Kaur.Result

  alias DB.Repo
  alias DB.Schema.{Comment, Flag, Statement, User, UserAction, Video, Vote}

  @doc """
  Resolve a user by its id or username
  """
  def get(_, %{id: id}, %{context: %{user: user = %{id: id}}}) do
    {:ok, user}
  end

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

  def get_logged_in(_, _, _) do
    {:ok, nil}
  end

  @doc """
  Resolve main picture URL for `user`
  """
  def picture_url(user, _, _) do
    {:ok, DB.Type.UserPicture.full_url(user, :thumb)}
  end

  @doc """
  Resolve small picture URL for `user`
  """
  def mini_picture_url(user, _, _) do
    {:ok, DB.Type.UserPicture.full_url(user, :mini_thumb)}
  end

  @watched_entities ~w(video speaker statement comment fact)a
  @watched_actions [
    :action_banned_bad_language,
    :action_banned_spam,
    :action_banned_irrelevant,
    :action_banned_not_constructive,
    :email_confirmed
  ]

  @doc """
  Resolve user actions history
  """
  def activity_log(user, %{offset: offset, limit: limit, direction: direction}, _) do
    UserAction
    |> where([a], a.entity in ^@watched_entities or a.type in ^@watched_actions)
    |> filter_by_user_action_direction(user, direction)
    |> DB.Query.order_by_last_inserted_desc()
    |> Repo.paginate(page: offset, page_size: limit)
    |> Result.ok()
  end

  @doc """
  Resolve user actions history
  """
  def pending_moderations(user, _, _) do
    Moderation.unread_count!(user)
    |> Result.ok()
  end

  @spec videos_added(
          atom() | %{:id => any(), optional(any()) => any()},
          %{:limit => any(), :offset => any(), optional(any()) => any()},
          any()
        ) :: {:ok, Scrivener.Page.t()}
  @doc """
  Get videos added by this user
  """
  def videos_added(user, %{offset: offset, limit: limit}, _) do
    {:ok, CF.Videos.added_by_user(user, page: offset, page_size: limit)}
  end

  @doc """
  Get the number of available flags for this user.
  Returns -1 for unlimited flags (publishers) or the remaining number of flags.
  Returns 0 if the user cannot flag comments.
  """
  def available_flags(user, _, _) do
    case UserPermissions.check(user, :flag, :comment) do
      {:ok, num_available} -> {:ok, num_available}
      {:error, _reason} -> {:ok, 0}
    end
  end

  @spec votes(nil | %{:id => any(), optional(any()) => any()}, any(), any()) :: {:ok, any()}
  @doc """
  Get user's votes on comments for a specific video as a map (commentId => vote value).
  Returns all votes if neither video_id nor video_hash_id are provided.
  """
  def votes(nil, _, _), do: {:ok, %{}}

  def votes(user, args, _) do
    video_id = Map.get(args, :video_id)
    video_hash_id = Map.get(args, :video_hash_id)

    query = Vote.user_votes(Vote, user)

    query =
      cond do
        video_id ->
          Vote.video_votes(query, %{id: video_id})

        video_hash_id ->
          Vote.video_votes(query, %{hash_id: video_hash_id})

        true ->
          query
      end

    votes =
      query
      |> select([v], {v.comment_id, v.value})
      |> Repo.all()
      |> Enum.into(%{})

    {:ok, votes}
  end

  @spec flags(nil | %{:id => any(), optional(any()) => any()}, any(), any()) :: {:ok, map()}
  @doc """
  Get comment IDs the user has flagged for a specific video as a map (commentId => true).
  Returns all flagged comment IDs if neither video_id nor video_hash_id are provided.
  """
  def flags(nil, _, _), do: {:ok, %{}}

  def flags(user, args, _) do
    video_id = Map.get(args, :video_id)
    video_hash_id = Map.get(args, :video_hash_id)

    query =
      from(
        f in Flag,
        join: a in UserAction,
        on: f.action_id == a.id,
        where: f.source_user_id == ^user.id,
        where: not is_nil(a.comment_id)
      )

    query =
      cond do
        video_id ->
          from([f, a] in query,
            join: c in Comment,
            on: c.id == a.comment_id,
            join: s in Statement,
            on: c.statement_id == s.id,
            where: s.video_id == ^video_id
          )

        video_hash_id ->
          from([f, a] in query,
            join: c in Comment,
            on: c.id == a.comment_id,
            join: s in Statement,
            on: c.statement_id == s.id,
            join: v in Video,
            on: s.video_id == v.id,
            where: v.hash_id == ^video_hash_id
          )

        true ->
          query
      end

    flags =
      query
      |> select([_f, a], {a.comment_id, true})
      |> Repo.all()
      |> Enum.into(%{})

    {:ok, flags}
  end

  defp filter_by_user_action_direction(query, user, direction) when direction == :all,
    do: where(query, [a], a.user_id == ^user.id or a.target_user_id == ^user.id)

  defp filter_by_user_action_direction(query, user, direction) when direction == :author,
    do: where(query, [a], a.user_id == ^user.id)

  defp filter_by_user_action_direction(query, user, direction) when direction == :target,
    do: where(query, [a], a.target_user_id == ^user.id and a.user_id != ^user.id)
end
