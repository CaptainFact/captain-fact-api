defmodule CaptainFact.Accounts.UserPermissions do
  @moduledoc """
  Check and log user permissions. State is a map looking like this :
  """

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias CaptainFact.Actions.Recorder
  defmodule PermissionsError do
    defexception message: "forbidden", plug_status: 403
  end

  @daily_limit 24 * 60 * 60 # 24 hours
  @weekly_limit 7 * @daily_limit # 1 week

  @limit_warning_threshold 5
  @levels [-30, -5, 15, 30, 75, 125, 200, 500, 1000]
  @reverse_levels Enum.reverse(@levels)
  @nb_levels Enum.count(@levels)
  @lowest_acceptable_reputation List.first(@levels)
  @limitations %{
    #                        /!\ |️ New user          | Confirmed user
    # reputation            {-30 , -5 , 15 , 30 , 75 , 125 , 200 , 500 , 1000}
    #-------------------------------------------------------------------------
    create: %{
      comment:              { 2  ,  5 , 7  , 10 , 15 ,  50 , 75  , 100 , 200 },
      statement:            { 2  ,  2 , 6  , 10 , 30 ,  50 , 100 , 100 , 100 },
      speaker:              { 0  ,  0 , 0  , 0  , 3  ,  10 ,  15 , 20  , 40  },
    },
    add: %{
      video:                { 0  ,  0 ,  0 , 0  , 0  ,  0  ,  1  ,  2  ,  3  },
      speaker:              { 0  ,  0 ,  0 , 0  , 5  ,  30 ,  50 , 100 , 100 },
    },
    update: %{
      statement:            { 0  ,  0 ,  2 ,  5 , 10 ,  50 , 100 , 100 , 100 },
      speaker:              { 0  ,  0 ,  0 ,  0 , 5  ,  20 ,  30 ,  40 ,  80 },
      video:                { 0  ,  0 ,  0 ,  0 , 0  ,   0 ,  5  ,  10 ,  20 },
      user:                 { 5  ,  5 ,  5 ,  5 , 5  ,   5 ,  5  ,  5  ,  5  },
    },
    delete: %{
      comment:              { 10  , 20, 30 , 50 , 75 , 300 , 300 , 300 , 300 },
    },
    remove: %{
      statement:            { 0  ,  0 ,  0 ,  0 ,  0 ,  5  ,  10 ,  15 ,  25 },
      speaker:              { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   5 ,  20 ,  40 },
    },
    restore: %{
      statement:            { 0  ,  0 ,  0 ,  0 ,  0 ,  15 ,  20 ,  30 ,  50 },
      speaker:              { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,  10 ,  30 ,  60 }
    },
    flag: %{
      comment:              { 0  ,  0 ,  0 ,  0 ,  2 ,   5 ,  10 ,  15 ,  20 },
    },
    # Wildcards actions (they don't care about the entity type)
    vote_up:                { 0  ,  3 ,  5 , 10 , 15 ,  30 ,  50 ,  75 , 100 },
    vote_down:              { 0  ,  0 ,  2 ,  5 , 10 ,  20 ,  40 ,  80 , 100 },
    self_vote:              { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   3 ,   5 },
    revert_vote_up:         { 0  ,  10, 25 , 30 , 50 ,  75 ,  75 , 100 , 100 },
    revert_vote_down:       { 0  ,  10, 25 , 30 , 50 ,  75 ,  75 , 100 , 100 },
    revert_self_vote:       { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   3 ,   5 },
    collective_moderation:  { 0  ,  0 ,  0 ,  0 ,  0 ,   0  ,  5 ,   10 , 50 }
  }
  @error_not_enough_reputation "not_enough_reputation"
  @error_limit_reached "limit_reached"

  # --- API ---

  @doc """
  Check if user can execute action. Return `{:ok, nb_available}` if yes,
  `{:error, reason}` otherwise. This method is bypassed and returns {:ok, -1}
  for :add :video actions if user is publisher.

  `nb_available` is -1 if there is no limit.
  `entity` may be nil **only if** we're checking for a wildcard
  limitation(ex: collective_moderation)

  ## Examples
      iex> alias CaptainFact.Accounts.UserPermissions
      iex> alias CaptainFact.Actions.Recorder
      iex> user = DB.Factory.insert(:user, %{reputation: 45})
      iex> UserPermissions.check(user, :create, :comment)
      {:ok, 10}
      iex> UserPermissions.check(%{user | reputation: -42}, :remove, :statement)
      {:error, "not_enough_reputation"}
      iex> limitation = UserPermissions.limitation(user, :create, :comment)
      iex> for _ <- 1..limitation, do: Recorder.record!(user, :create, :comment)
      iex> UserPermissions.check(user, :create, :comment)
      {:error, "limit_reached"}
  """
  def check(%User{is_publisher: true}, :add, :video), do: {:ok, -1}
  def check(user = %User{}, action_type, entity) do
    limit = limitation(user, action_type, entity)
    if (limit == 0) do
      {:error, @error_not_enough_reputation}
    else
      action_count = action_count(user, action_type, entity)
      if action_count >= limit do
        if action_count >= limit + @limit_warning_threshold,
          do: Logger.warn("User #{user.username} (#{user.id}) overthrown its limit for [#{action_type} #{entity}] (#{action_count}/#{limit})")
        {:error, @error_limit_reached}
      else
        {:ok, limit - action_count}
      end
    end
  end
  def check(nil, _, _), do: {:error, "unauthorized"}
  def check!(user, action_type, entity \\ nil)
  def check!(user = %User{}, action_type, entity) do
    case check(user, action_type, entity) do
      {:error, message} -> raise %PermissionsError{message: message}
      {:ok, nb_available} -> nb_available
    end
  end
  def check!(user_id, action_type, entity) when is_integer(user_id),
    do: check!(do_load_user!(user_id), action_type, entity)
  def check!(nil, _, _),
    do: raise %PermissionsError{message: "unauthorized"}

  @doc """
  Count the number of occurences of this user / action type in limited perdiod.
  """
  def action_count(user, :add, :video),
    do: Recorder.count(user, :add, :video, @weekly_limit)
  def action_count(user, action_type, entity) do
    if is_wildcard_limitation(action_type) do
      Recorder.count_wildcard(user, action_type, @daily_limit)
    else
      Recorder.count(user, action_type, entity, @daily_limit)
    end
  end

  def limitation(user = %User{}, action_type, entity) do
    case level(user) do
      -1 -> 0 # Reputation under minimum user can't do anything
      level ->
        case Map.get(@limitations, action_type) do
          l when is_tuple(l) -> elem(l, level)
          l when is_map(l) -> elem(Map.get(l, entity), level)
        end
    end
  end

  def is_wildcard_limitation(action_type) do
    is_tuple(Map.get(@limitations, action_type))
  end

  def level(%User{reputation: reputation}) do
    if reputation < @lowest_acceptable_reputation,
      do: -1,
      else: (@nb_levels - 1) - Enum.find_index(@reverse_levels, &(reputation >= &1))
  end

  # Static getters
  def limitations(), do: @limitations
  def nb_levels(), do: @nb_levels

  defp do_load_user!(nil), do: raise %PermissionsError{message: "unauthorized"}
  defp do_load_user!(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> select([:id, :reputation])
    |> Repo.one!()
  end
end
