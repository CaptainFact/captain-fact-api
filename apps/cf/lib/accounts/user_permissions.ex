defmodule CF.Accounts.UserPermissions do
  @moduledoc """
  Check and log user permissions. State is a map looking like this :
  """

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.User
  alias CF.Actions

  defmodule PermissionsError do
    defexception message: "forbidden", plug_status: 403
  end

  @error_not_enough_reputation "not_enough_reputation"
  @error_limit_reached "limit_reached"

  @limit_warning_threshold 5
  @levels [-30, -5, 15, 30, 75, 125, 200, 500, 1000]
  @reverse_levels Enum.reverse(@levels)
  @nb_levels Enum.count(@levels)
  @lowest_acceptable_reputation List.first(@levels)

  # Limitations
  # @external_resource specify the file dependency to compiler
  # See https://hexdocs.pm/elixir/Module.html#module-external_resource
  @limitations_file Path.join(:code.priv_dir(:cf), "limitations.yaml")
  @external_resource @limitations_file
  @limitations CF.Utils.load_yaml_config(@limitations_file)

  # --- API ---

  @doc """
  Check if user can execute action. Return `{:ok, nb_available}` if yes,
  `{:error, reason}` otherwise. This method is bypassed and returns {:ok, -1}
  if user is publisher.

  `nb_available` is -1 if there is no limit.
  `entity` may be nil **only if** we're checking for a wildcard
  limitation(ex: collective_moderation)

  ## Examples
      iex> alias CF.Accounts.UserPermissions
      iex> user = DB.Factory.insert(:user, %{reputation: 45})
      iex> UserPermissions.check(user, :create, :comment)
      {:ok, 7}
      iex> UserPermissions.check(%{user | reputation: -42}, :remove, :statement)
      {:error, "not_enough_reputation"}
  """
  def check(%User{is_publisher: true}, _, _),
    do: {:ok, -1}

  def check(user = %User{}, action_type, entity) do
    limit = limitation(user, action_type, entity)

    if limit == 0 do
      {:error, @error_not_enough_reputation}
    else
      action_count = action_count(user, action_type, entity)

      if action_count >= limit do
        # User should never be able to overthrow daily limitations, we must
        # output a warning if we identify such an issue
        if action_count >= limit + @limit_warning_threshold,
          do:
            Logger.warn(fn ->
              "User #{user.username} (#{user.id}) overthrown its limit for [#{action_type} #{
                entity
              }] (#{action_count}/#{limit})"
            end)

        {:error, @error_limit_reached}
      else
        {:ok, limit - action_count}
      end
    end
  end

  def check(nil, _, _),
    do: {:error, "unauthorized"}

  @doc """
  Same as `check/1` bu raise a PermissionsError if user doesn't have the right
  permissions.
  """
  def check!(user, action_type, entity \\ nil)

  def check!(user = %User{}, action_type, entity) do
    case check(user, action_type, entity) do
      {:error, message} ->
        raise %PermissionsError{message: message}

      {:ok, nb_available} ->
        nb_available
    end
  end

  def check!(user_id, action_type, entity) when is_integer(user_id),
    do: check!(do_load_user!(user_id), action_type, entity)

  def check!(nil, _, _),
    do: raise(%PermissionsError{message: "unauthorized"})

  @doc """
  Count the number of occurences of this user / action type in limited perdiod.
  """
  def action_count(user, action_type = :add, entity = :video) do
    Actions.count(user, action_type, entity, hard_limitations_period())
  end

  def action_count(user, action_type, entity) do
    if is_wildcard_limitation(action_type) do
      Actions.count_wildcard(user, action_type, soft_limitations_period())
    else
      Actions.count(user, action_type, entity, soft_limitations_period())
    end
  end

  @fifteen_minutes 15 * 60
  @three_hours 3 * 60 * 60

  @doc """
  Get the limit, in seconds, on which the actions are analyzed for limitations.
  This uses a variable from env to make it configurable on the fly.
  """
  def soft_limitations_period,
    do: Application.get_env(:cf, :soft_limitations_period, @fifteen_minutes)

  @doc """
  Same as `soft_limitations_period/0` but less permissive, only used when adding
  new videos.
  """
  def hard_limitations_period,
    do: Application.get_env(:cf, :hard_limitations_period, @three_hours)

  @doc """
  Get the limitations for a given user and action type.
  """
  def limitation(user = %User{}, action_type, entity) do
    case level(user) do
      -1 ->
        # Reputation under minimum user can't do anything
        0

      level ->
        case Map.get(@limitations, action_type) do
          l when is_list(l) -> Enum.at(l, level)
          l when is_map(l) -> Enum.at(Map.get(l, entity), level)
        end
    end
  end

  def is_wildcard_limitation(action_type) do
    is_list(Map.get(@limitations, action_type))
  end

  def level(%User{reputation: reputation}) do
    if reputation < @lowest_acceptable_reputation,
      do: -1,
      else: @nb_levels - 1 - Enum.find_index(@reverse_levels, &(reputation >= &1))
  end

  defp do_load_user!(nil),
    do: raise(%PermissionsError{message: "unauthorized"})

  defp do_load_user!(user_id) do
    User
    |> where([u], u.id == ^user_id)
    |> select([:id, :reputation, :is_publisher])
    |> Repo.one!()
  end

  # Static getters

  def limitations(), do: @limitations

  def nb_levels(), do: @nb_levels
end
