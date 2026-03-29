defmodule CF.Statements do
  @moduledoc """
  Functions to manipulate statements
  """

  alias Ecto.Multi
  alias Kaur.Result

  alias DB.Schema.Statement
  alias DB.Repo

  alias CF.Accounts.UserPermissions

  import CF.Actions.ActionCreator,
    only: [action_create: 2, action_update: 2, action_remove: 2, action_restore: 2]

  @doc """
  Paginated list of statements (filters, offset, limit in `args`).
  """
  def paginated_list(%{offset: offset, limit: limit} = args) do
    Statement
    |> Statement.query_list(Map.get(args, :filters, []))
    |> Repo.paginate(page: offset, page_size: limit)
    |> Result.ok()
  end

  @doc """
  Creates a statement and the corresponding user action. `attrs` must include `video_id`
  (atom or string key). Other entries are passed to `Statement.changeset/2`.
  """
  def create_statement(user_id, attrs) when is_integer(user_id) and is_map(attrs) do
    UserPermissions.check!(user_id, :create, :statement)

    video_id = attrs[:video_id] || attrs["video_id"]
    changeset = Statement.changeset(%Statement{video_id: video_id}, attrs)

    Multi.new()
    |> Multi.insert(:statement, changeset)
    |> Multi.run(:action_create, fn _repo, %{statement: statement} ->
      Repo.insert(action_create(user_id, statement))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{statement: statement}} ->
        {:ok, statement}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Update given statement. Raises if the user doesn't have permission to do that.
  """
  def update!(user_id, statement = %Statement{is_removed: false}, changes) do
    UserPermissions.check!(user_id, :update, :statement)
    changeset = Statement.changeset_update(statement, changes)

    if changeset.changes == %{} do
      Result.ok(statement)
    else
      Multi.new()
      |> Multi.update(:statement, changeset)
      |> Multi.insert(:action_update, action_update(user_id, changeset))
      |> Repo.transaction()
      |> case do
        {:ok, %{statement: updated_statement}} ->
          Result.ok(updated_statement)

        {:error, _operation, reason, _changes} ->
          Result.error(reason)
      end
    end
  end

  @doc """
  Soft-removes a statement and records the user action.
  """
  def remove_statement(user_id, statement = %Statement{}) do
    UserPermissions.check!(user_id, :remove, :statement)

    Multi.new()
    |> Multi.update(:statement, Statement.changeset_remove(statement))
    |> Multi.insert(:action_remove, action_remove(user_id, statement))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, statement}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  @doc """
  Restores a removed statement and records the user action.
  """
  def restore_statement(user_id, statement = %Statement{}) do
    UserPermissions.check!(user_id, :restore, :statement)

    Multi.new()
    |> Multi.update(:statement, Statement.changeset_restore(statement))
    |> Multi.insert(:action_restore, action_restore(user_id, statement))
    |> Repo.transaction()
    |> case do
      {:ok, %{action_restore: action, statement: statement}} ->
        {:ok, %{statement: statement, action: action}}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end
end
