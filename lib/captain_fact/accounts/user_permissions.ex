defmodule CaptainFact.Accounts.UserPermissions do
  @moduledoc """
  Check and log user permissions. State is a map looking like this :
  """

  require Logger
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Accounts.{User, UserState}
  defmodule PermissionsError do
    defexception message: "forbidden", plug_status: 403
  end

  @user_state_key :actions_count
  @levels [-30, -5, 15, 30, 50, 100, 200, 500, 1000]
  @reverse_levels Enum.reverse(@levels)
  @nb_levels Enum.count(@levels)
  @lowest_acceptable_reputation List.first(@levels)
  @limitations %{
    #                        /!\ |️ New user          | Confirmed user
    # reputation            {-30 , -5 , 15 , 30 , 50 , 100 , 200 , 500 , 1000}
    #-------------------------------------------------------------------------
    add_video:              { 0  ,  1 ,  5 , 10 , 15 ,  30 ,  30 ,  30 ,  30 },
    edit_comment:           { 3  , 10 , 15 , 30 , 30 , 100 , 100 , 100 , 100 },
    add_comment:            { 3  ,  5 , 10 , 20 , 30 , 200 , 200 , 200 , 200 },
    # Vote
    self_vote:              { 3  ,  10, 15 , 30 , 50 , 250 , 250 , 250 , 250 },
    vote_up:                { 0  ,  5 , 15 , 30 , 45 , 300 , 500 , 500 , 500 },
    vote_down:              { 0  ,  0 ,  0 ,  5 , 10 ,  20 ,  40 ,  80 , 150 },
    # Flag / Approve
    approve_history_action: { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    flag_history_action:    { 0  ,  0 ,  0 ,  0 ,  0 ,   0 ,   0 ,   0 ,   0 },
    flag_comment:           { 0  ,  0 ,  0 ,  1 ,  3 ,   5 ,  10 ,  15 ,  30 },
    # Statements
    add_statement:          { 0  ,  2 ,  5 , 15 , 30 ,  50 , 100 , 100 , 100 },
    edit_statement:         { 0  ,  0 ,  0 ,  3 ,  5 ,  50 , 100 , 100 , 100 },
    remove_statement:       { 0  ,  0 ,  0 ,  3 ,  5 ,  10 ,  10 ,  10 ,  10 },
    restore_statement:      { 0  ,  0 ,  0 ,  3 ,  5 ,  15 ,  15 ,  15 ,  15 },
    # Speakers
    add_speaker:            { 0  ,  0 ,  3 ,  5 , 10 ,  30 ,  50 , 100 , 100 },
    remove_speaker:         { 0  ,  0 ,  3 ,  5 , 10 ,  30 ,  50 , 100 , 100 },
    edit_speaker:           { 0  ,  0 ,  3 ,  5 , 10 ,  30 ,  50 , 100 , 100 },
    restore_speaker:        { 0  ,  0 ,  0 ,  5 , 10 ,  30 ,  50 , 100 , 100 }
  }

  # --- API ---

  @doc """
  The safe way to ensure limitations and record actions as state is locked during `func` execution.
  Raises PermissionsError if user doesn't have the permission.

  lock! will do an optimistic lock by incrementing the counter for this action then execute func.
  Returnning a tupe like {:error, _} or raiseing / raising in `func` will revert the action
  """
  def lock!(user = %User{}, action, func) when is_atom(action) do
    limit = limitation(user, action)
    if (limit == 0), do: raise %PermissionsError{message: "not_enough_reputation"}

    # Optimistic lock
    lock_status = UserState.get_and_update(user, @user_state_key, fn state ->
      state = state || %{}
      if Map.get(state, action, 0) >= limit,
        do: {:error, state},
        else: {:ok, do_record_action(state, action)}
    end)
    if lock_status == :error, do: raise %PermissionsError{message: "limit_reached"}

    try do
      func.(user)
    catch
      e ->
        UserState.update(user, @user_state_key, 0, &do_revert_action(&1, action))
        raise e
    rescue
      e ->
        UserState.update(user, @user_state_key, 0, &do_revert_action(&1, action))
        reraise e, System.stacktrace
    else
      response = {:error, _} ->
        UserState.update(user, @user_state_key, 0, &do_revert_action(&1, action))
        response
      response -> response
    end
  end
  def lock!(user_id, action, func) when is_integer(user_id) and is_atom(action),
    do: lock!(do_load_user!(user_id), action, func)
  def lock!(nil, _, _), do: raise %PermissionsError{message: "unauthorized"}

  @doc """
  Run Repo.transaction while locking permissions. Usefull when piping
  """
  def lock_transaction!(transaction = %Ecto.Multi{}, user, action) when is_atom(action),
    do: lock!(user, action, fn _ -> Repo.transaction(transaction) end)

  @doc """
  Check if user can execute action. Return {:ok, nb_available} if yes, {:error, reason} otherwise
  ## Examples
      iex> alias CaptainFact.Accounts.{User, UserPermissions}
      iex> user = %User{id: 1, reputation: 42}
      iex> UserPermissions.check(user, :add_comment)
      {:ok, 20}
      iex> UserPermissions.check(%{user | reputation: -42}, :remove_statement)
      {:error, "not_enough_reputation"}
      iex> for _ <- 0..50, do: UserPermissions.record_action(user, :add_comment)
      iex> UserPermissions.check(user, :add_comment)
      {:error, "limit_reached"}
  """
  def check(user = %User{}, action) when is_atom(action) do
    limit = limitation(user, action)
    if (limit == 0) do
      {:error, "not_enough_reputation"}
    else
      action_count = Map.get(UserState.get(user, @user_state_key, %{}), action, 0)
      limitation = limitation(user, action)
      if action_count >= limitation,
      do: {:error, "limit_reached"},
      else: {:ok, limitation - action_count}
    end
  end
  def check(nil, _), do: {:error, "unauthorized"}
  def check!(user = %User{}, action) when is_atom(action) do
    case check(user, action) do
      {:ok, _} -> :ok
      {:error, message} -> raise %PermissionsError{message: message}
    end
  end
  def check!(user_id, action) when is_integer(user_id) and is_atom(action) do
     check!(do_load_user!(user_id), action)
  end
  def check!(nil, _), do: raise %PermissionsError{message: "unauthorized"}

  @doc """
  Doesn't verify user's limitation nor reputation, you need to check that by yourself
  """
  def record_action(user = %User{}, action) when is_atom(action) do
    UserState.update(user, @user_state_key, %{action => 1}, &do_record_action(&1, action))
  end
  def record_action(user_id, action) when is_integer(user_id),
    do: record_action(%User{id: user_id}, action)

  def user_nb_action_occurences(user = %User{}, action) do
    UserState.get(user, @user_state_key, %{})
    |> Map.get(action, 0)
  end

  def limitation(user = %User{}, action) do
    case level(user) do
      -1 -> 0 # Reputation under minimum user can't do anything
      level -> elem(Map.get(@limitations, action), level)
    end
  end

  def level(%User{reputation: reputation}) do
    if reputation < @lowest_acceptable_reputation,
      do: -1,
      else: (@nb_levels - 1) - Enum.find_index(@reverse_levels, &(reputation >= &1))
  end

  # Static getters
  def limitations(), do: @limitations
  def nb_levels(), do: @nb_levels

  # Methods

  defp do_record_action(user_actions, action), do: Map.update(user_actions, action, 1, &(&1 + 1))
  defp do_revert_action(user_actions, action), do: Map.update(user_actions, action, 0, &(&1 - 1))

  defp do_load_user!(nil), do: raise %PermissionsError{message: "unauthorized"}
  defp do_load_user!(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> select([:id, :reputation])
    |> Repo.one!()
  end
end
