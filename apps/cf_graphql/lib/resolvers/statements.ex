defmodule CF.Graphql.Resolvers.Statements do
  @moduledoc """
  Resolver for `DB.Schema.Statement`
  """

  alias Kaur.Result

  alias Ecto.Multi
  alias DB.Repo
  alias DB.Schema.Statement
  alias CF.Accounts.UserPermissions
  alias CF.Actions.ActionCreator
  alias CF.Graphql.Subscriptions
  alias CF.Algolia.StatementsIndex
  alias CF.Statements

  import CF.Actions.ActionCreator, only: [action_remove: 2, action_restore: 2]

  # Queries

  def paginated_list(_root, args = %{offset: offset, limit: limit}, _info) do
    Statement
    |> Statement.query_list(Map.get(args, :filters, []))
    |> Repo.paginate(page: offset, page_size: limit)
    |> Result.ok()
  end

  # Mutations

  def create(_root, args = %{video_id: video_id, text: _text, time: _time}, %{
        context: %{user: user}
      }) do
    user_id = user.id
    UserPermissions.check!(user_id, :create, :statement)

    # Absinthe automatically converts GraphQL camelCase to snake_case
    changeset = Statement.changeset(%Statement{video_id: video_id}, args)

    Multi.new()
    |> Multi.insert(:statement, changeset)
    |> Multi.run(:action_create, fn _repo, %{statement: statement} ->
      Repo.insert(ActionCreator.action_create(user_id, statement))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{statement: statement}} ->
        Subscriptions.publish_statement_added(statement)
        StatementsIndex.save_object(statement)
        {:ok, statement}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  def update(_root, args = %{id: id}, %{context: %{user: user}}) when not is_nil(id) do
    user_id = user.id
    statement = Repo.get_by!(Statement, id: id, is_removed: false)

    case Statements.update!(user_id, statement, args) do
      {:ok, updated_statement} ->
        Subscriptions.publish_statement_updated(updated_statement)
        StatementsIndex.save_object(updated_statement)
        {:ok, updated_statement}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(_root, %{id: id}, %{context: %{user: user}}) do
    user_id = user.id
    UserPermissions.check!(user_id, :remove, :statement)
    statement = Repo.get_by!(Statement, id: id, is_removed: false)

    Multi.new()
    |> Multi.update(:statement, Statement.changeset_remove(statement))
    |> Multi.insert(:action_remove, action_remove(user_id, statement))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        Subscriptions.publish_statement_removed(id, statement.video_id)
        StatementsIndex.delete_object(statement)
        {:ok, %{id: id}}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end

  def restore(_root, %{id: id}, %{context: %{user: user}}) do
    user_id = user.id
    UserPermissions.check!(user_id, :restore, :statement)
    statement = Repo.get_by!(Statement, id: id, is_removed: true)

    Multi.new()
    |> Multi.update(:statement, Statement.changeset_restore(statement))
    |> Multi.insert(:action_restore, action_restore(user_id, statement))
    |> Repo.transaction()
    |> case do
      {:ok, %{action_restore: action, statement: statement}} ->
        Subscriptions.publish_video_history_action(action, statement.video_id)
        Subscriptions.publish_statement_history_action(action, statement.id)
        Subscriptions.publish_statement_added(statement)
        StatementsIndex.save_object(statement)
        {:ok, statement}

      {:error, _operation, reason, _changes} ->
        {:error, reason}
    end
  end
end
