defmodule CaptainFact.UserPermissions do
  @moduledoc """
  Check and log user permissions. State is a map looking like this :
  ```
  %{
    user_id => %{
      :action_atom => 42 # Number of occurences in the last 24h
    }
  }
  ```
  """

  require Logger
  import Ecto.Query
  alias CaptainFact.{ Repo, User, UserState }

  defmodule PermissionsError do
    defexception message: "forbidden"
  end

  @user_state_key :actions_count
  @levels [-30, -5, 15, 30, 50, 100, 200, 500, 1000]
  @reverse_levels Enum.reverse(@levels)
  @nb_levels Enum.count(@levels)
  @limitations %{
    #                       Negative  |️ New user     | Confirmed user
    # reputation            {-30 , -5 , 15 , 30 , 50 , 100 , 200 , 500 , 1000}
    #-------------------------------------------------------------------------
    edit_comment:           { 3  , 10 , 15 , 30 , 30 , 100 , 100 , 100 , 100 },
    add_comment:            { 0  ,  3 , 10 , 20 , 30 , 200 , 200 , 200 , 200 },
    add_video:              { 0  ,  1 ,  5 , 10 , 15 ,  30 ,  30 ,  30 ,  30 },
    # Vote
    vote_up:                { 0  ,  0 , 20 , 30 , 45 , 300 , 500 , 500 , 500 },
    vote_down:              { 0  ,  0 ,  0 ,  5 , 10 ,  20 ,  40 ,  80 , 150 },
    # Flag / Approve
    approve_history_action: { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    flag_history_action:    { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    flag_comment:           { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    # Statements
    add_statement:          { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    edit_other_statement:   { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    remove_statement:       { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    restore_statement:      { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    # Speakers
    add_speaker:            { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    remove_speaker:         { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    edit_speaker:           { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    restore_speaker:        { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 }
  }

  # --- API ---

  @doc """
  Get an atom describing the vote.
  ## Examples
      iex> alias CaptainFact.{ User, UserPermissions }
      iex> user = %User{id: 1, reputation: 42}
      iex> UserPermissions.check(user, :add_comment)
      :ok
      iex> UserPermissions.check(%{user | reputation: -42}, :remove_statement)
      {:error, "not enough reputation"}
      iex> for _ <- 0..50, do: UserPermissions.record_action(user, :add_comment)
      iex> UserPermissions.check(user, :add_comment)
      {:error, "limit reached"}
  """
  def check(user = %User{}, action) when is_atom(action) do
    limit = limitation(user, action)
    if (limit == 0) do
      {:error, "not enough reputation"}
    else
      action_count = Map.get(UserState.get(user, @user_state_key, %{}), action, 0)
      if action_count >= limitation(user, action),
      do: {:error, "limit reached"},
      else: :ok
    end
  end
  def check!(user_id, action) when is_integer(user_id) and is_atom(action) do
     check(do_load_user!(user_id), action)
  end

  @doc """
  Doesn't verify user's limitation nor reputation, you need to check that by yourself
  """
  def record_action(user = %User{}, action) when is_atom(action) do
    UserState.update(user, @user_state_key, %{action => 1}, &do_record_action(&1, action))
  end
  def record_action(user_id, action) when is_integer(user_id),
    do: record_action(%User{id: user_id}, action)

  @doc """
  The safe way to ensure limitations as state is locked during `func` execution.
  Should be used to verify sensitive actions, but not for those where limitation is high / not
  important because of perfomances impact.
  Raises PermissionsError if user doesn't have the permission.
  If user is an integer, it will be loaded from DB
  """
  def lock!(user = %User{}, action, func) when is_atom(action) do
    limit = limitation(user, action)
    if (limit == 0),
      do: raise PermissionsError, message: "not enough reputation"

    case UserState.get_and_update(user, @user_state_key, fn state ->
      state = state || %{}
      if Map.get(state, action, 0) >= limitation(user, action) do
        {{:error, "limit reached"}, state}
      else
        try do
          result = func.(user)
          {{:ok, result}, do_record_action(state, action)}
        rescue
          e -> {{:exception, e}, state}
        end
      end
    end) do
      {:error, message} -> raise PermissionsError, message: message
      {:exception, e} -> raise e
      {:ok, result} -> result
    end
  end
  def lock!(user_id, action, func) when is_integer(user_id) and is_atom(action),
     do: lock!(do_load_user!(user_id), action, func)

  def user_nb_action_occurences(user = %User{}, action) do
    UserState.get(user, @user_state_key, %{})
    |> Map.get(action, 0)
  end

  def limitation(user = %User{}, action) do
    elem(Map.get(@limitations, action), level(user))
  end

  def level(%User{reputation: reputation}) do
    (@nb_levels - 1) - (Enum.find_index(@reverse_levels, &(reputation >= &1)) || @nb_levels - 1)
  end

  # Static getters
  def limitations(), do: @limitations
  def nb_levels(), do: @nb_levels

  # Methods

  defp do_record_action(user_actions, action),
    do: Map.update(user_actions, action, 1, &(&1 + 1))

  defp do_load_user!(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> select([:id, :reputation])
    |> Repo.one!()
  end
end
