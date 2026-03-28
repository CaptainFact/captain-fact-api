defmodule CF.Graphql.Resolvers.Statements do
  @moduledoc """
  Resolver for `DB.Schema.Statement`
  """

  alias DB.Repo
  alias DB.Schema.Statement
  alias CF.Algolia.StatementsIndex
  alias CF.Graphql.Subscriptions
  alias CF.Statements

  # Queries

  def paginated_list(_root, args = %{offset: _offset, limit: _limit}, _info) do
    Statements.paginated_list(args)
  end

  # Mutations

  def create(_root, args = %{video_id: _video_id, text: _text, time: _time}, %{
        context: %{user: user}
      }) do
    case Statements.create_statement(user.id, args) do
      {:ok, statement} ->
        Subscriptions.publish_statement_added(statement)
        StatementsIndex.save_object(statement)
        {:ok, statement}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update(_root, args = %{id: id}, %{context: %{user: user}}) when not is_nil(id) do
    statement = Repo.get_by!(Statement, id: id, is_removed: false)

    case Statements.update!(user.id, statement, args) do
      {:ok, updated_statement} ->
        Subscriptions.publish_statement_updated(updated_statement)
        StatementsIndex.save_object(updated_statement)
        {:ok, updated_statement}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(_root, %{id: id}, %{context: %{user: user}}) do
    statement = Repo.get_by!(Statement, id: id, is_removed: false)

    case Statements.remove_statement(user.id, statement) do
      {:ok, statement} ->
        Subscriptions.publish_statement_removed(statement.id, statement.video_id)
        StatementsIndex.delete_object(statement)
        {:ok, %{id: statement.id}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def restore(_root, %{id: id}, %{context: %{user: user}}) do
    statement = Repo.get_by!(Statement, id: id, is_removed: true)

    case Statements.restore_statement(user.id, statement) do
      {:ok, %{statement: statement, action: action}} ->
        Subscriptions.publish_video_history_action(action, statement.video_id)
        Subscriptions.publish_statement_history_action(action, statement.id)
        Subscriptions.publish_statement_added(statement)
        StatementsIndex.save_object(statement)
        {:ok, statement}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
