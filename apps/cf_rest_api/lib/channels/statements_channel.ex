defmodule CF.RestApi.StatementsChannel do
  use CF.RestApi, :channel

  import CF.RestApi.UserSocket, only: [handle_in_authenticated: 4]

  import CF.Actions.ActionCreator, only: [action_create: 2, action_remove: 2]

  alias Ecto.Multi
  alias DB.Type.VideoHashId
  alias DB.Schema.Statement

  alias CF.Statements
  alias CF.Accounts.UserPermissions

  alias CF.RestApi.{StatementView, ErrorView}

  def join("statements:video:" <> video_hash_id, _payload, socket) do
    video_id = VideoHashId.decode!(video_hash_id)

    statements =
      Statement
      |> where(video_id: ^video_id)
      |> where(is_removed: false)
      |> Repo.all()

    {:ok, StatementView.render("index.json", statements: statements),
     assign(socket, :video_id, video_id)}
  end

  def handle_in(command, params, socket) do
    handle_in_authenticated(command, params, socket, &handle_in_authenticated!/3)
  end

  @doc """
  Add a new statement
  """
  def handle_in_authenticated!("new_statement", params, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :create, :statement)
    changeset = Statement.changeset(%Statement{video_id: video_id}, params)

    Multi.new()
    |> Multi.insert(:statement, changeset)
    |> Multi.run(:action_create, fn _repo, %{statement: statement} ->
      Repo.insert(action_create(user_id, statement))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{statement: statement}} ->
        rendered_statement = StatementView.render("show.json", statement: statement)
        broadcast!(socket, "statement_added", rendered_statement)
        {:reply, {:ok, rendered_statement}, socket}

      {:error, _operation, reason, _changes} ->
        {:reply, {:error, ErrorView.render("error.json", reason: reason)}, socket}
    end
  end

  def handle_in_authenticated!("update_statement", params = %{"id" => id}, socket) do
    statement = Repo.get_by!(Statement, id: id, is_removed: false)

    case Statements.update!(socket.assigns.user_id, statement, params) do
      {:ok, statement} ->
        rendered_statement = StatementView.render("show.json", statement: statement)
        broadcast!(socket, "statement_updated", rendered_statement)
        {:reply, :ok, socket}

      {:error, reason} ->
        {:reply, {:error, ErrorView.render("error.json", reason: reason)}, socket}
    end
  end

  def handle_in_authenticated!("remove_statement", %{"id" => id}, socket) do
    %{user_id: user_id} = socket.assigns
    UserPermissions.check!(user_id, :remove, :statement)
    statement = Repo.get_by!(Statement, id: id, is_removed: false)

    Multi.new()
    |> Multi.update(:statement, Statement.changeset_remove(statement))
    |> Multi.insert(:action_remove, action_remove(user_id, statement))
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        broadcast!(socket, "statement_removed", %{id: id})
        {:reply, :ok, socket}

      {:error, _, _reason, _} ->
        {:reply, :error, socket}
    end
  end
end
