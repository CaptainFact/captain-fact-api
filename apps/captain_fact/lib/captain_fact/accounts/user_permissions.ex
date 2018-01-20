defmodule CaptainFact.Accounts.UserPermissions do
  @moduledoc """
  Check and log user permissions. State is a map looking like this :
  """

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias CaptainFact.Accounts.User
  alias CaptainFact.Actions.Recorder
  defmodule PermissionsError do
    defexception message: "forbidden", plug_status: 403
  end

  @limitations_age 12 * 60 * 60 # 12 hours
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
      comment:              { 2  ,  5 , 7  , 20 , 30 , 200 , 200 , 200 , 200 },
      statement:            { 0  ,  2 , 6  , 10 , 30 ,  50 , 100 , 100 , 100 },
      speaker:              { 0  ,  0 , 0  , 3  , 8  ,  30 ,  50 , 100 , 100 },
    },
    add: %{
      video:                { 0  ,  0 ,  0 , 0  , 0  ,  0  ,  2  ,  5  ,  10 },
      speaker:              { 0  ,  0 ,  0 , 3  , 8  ,  30 ,  50 , 100 , 100 },
    },
    update: %{
      comment:              { 3  , 10 , 15 , 30 , 30 , 100 , 100 , 100 , 100 },
      statement:            { 0  ,  0 ,  0 ,  5 , 10 ,  50 , 100 , 100 , 100 },
      speaker:              { 0  ,  0 ,  0 ,  5 , 10 ,  30 ,  50 , 100 , 100 },
      video:                { 0  ,  0 ,  0 ,  0 , 0  ,  5  ,  8  ,  10 , 20  },
    },
    delete: %{
      # Not much risk here, as user can only delete own comments
      comment:              { 10  , 20, 30 , 50 , 75 , 300 , 300 , 300 , 300 },
    },
    remove: %{
      statement:            { 0  ,  0 ,  0 ,  0 ,  3 ,  10 ,  10 ,  10 ,  10 },
      speaker:              { 0  ,  0 ,  0 ,  0 ,  3 ,  30 ,  50 , 100 , 100 },
    },
    restore: %{
      statement:            { 0  ,  0 ,  0 ,  0 ,  5 ,  15 ,  15 ,  15 ,  15 },
      speaker:              { 0  ,  0 ,  0 ,  0 , 10 ,  30 ,  50 , 100 , 100 }
    },
    approve: %{
      video_debate_action:  { 0  ,  0 ,  0 ,  0 ,  0 ,   3 ,  10 ,  20 ,  30 },
    },
    flag: %{
      video_debate_action:  { 0  ,  0 ,  0 ,  5 ,  5 ,   5 ,   5 ,   5 ,   5 },
      comment:              { 0  ,  0 ,  1 ,  3 ,  3 ,   5 ,  10 ,  10 ,  10 },
    },
    vote_up:                { 0  ,  3 ,  7 , 10 , 15 ,  30 ,  50 ,  75 , 100 },
    vote_down:              { 0  ,  0 ,  2 ,  5 , 10 ,  20 ,  40 ,  80 , 100 },
    self_vote:              { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   3 ,   5 },
    revert_vote_up:         { 10  , 20, 30 , 50 , 75 , 150 , 300 , 500 , 500 },
    revert_vote_down:       { 10  , 20, 30 , 50 , 75 , 150 , 300 , 500 , 500 },
    revert_self_vote:       { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   3 ,   5 },
    collective_moderation:  { 0  ,  0 ,  0 ,  0 ,  0 ,   0  ,  0 ,   0 , 200 }
  }
  @error_not_enough_reputation "not_enough_reputation"
  @error_limit_reached "limit_reached"

  # --- API ---

  @doc """
  Check if user can execute action. Return {:ok, nb_available} if yes, {:error, reason} otherwise.

  `entity` may be nil **only if** we're checking for a wildcard limitation (ex: collective_moderation)

  ## Examples
      iex> alias CaptainFact.Accounts.UserPermissions
      iex> alias CaptainFact.Actions.Recorder
      iex> user = CaptainFact.Factory.insert(:user, %{reputation: 45})
      iex> UserPermissions.check(user, :create, :comment)
      {:ok, 20}
      iex> UserPermissions.check(%{user | reputation: -42}, :remove, :statement)
      {:error, "not_enough_reputation"}
      iex> limitation = UserPermissions.limitation(user, :create, :comment)
      iex> for _ <- 1..limitation, do: Recorder.record!(user, :create, :comment)
      iex> UserPermissions.check(user, :create, :comment)
      {:error, "limit_reached"}
  """
  def check(user = %User{}, action_type, entity) do
    limit = limitation(user, action_type, entity)
    if (limit == 0) do
      {:error, @error_not_enough_reputation}
    else
      action_count = if is_wildcard_limitation(action_type),
        do: Recorder.count_wildcard(user, action_type, @limitations_age),
        else: Recorder.count(user, action_type, entity, @limitations_age)
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
