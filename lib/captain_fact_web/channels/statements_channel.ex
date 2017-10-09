defmodule CaptainFactWeb.StatementsChannel do
  use CaptainFactWeb, :channel

  import CaptainFactWeb.UserSocket, only: [handle_in_authenticated: 4]
  import CaptainFact.VideoDebate.ActionCreator,
    only: [action_create: 3, action_update: 3, action_delete: 3]

  alias Ecto.Multi
  alias CaptainFact.Videos.VideoHashId
  alias CaptainFactWeb.{Statement, StatementView, ErrorView}
  alias CaptainFact.Accounts.UserPermissions


  def join("statements:video:" <> video_id_hash, _payload, socket) do
    video_id = VideoHashId.decode!(video_id_hash)
    statements =
      Statement
      |> where(video_id: ^video_id)
      |> where(is_removed: false)
      |> Repo.all
    rendered_statements = StatementView.render("index.json", statements: statements)
    {:ok, rendered_statements, assign(socket, :video_id, video_id)}
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
    Multi.new
    |> Multi.insert(:statement, changeset)
    |> Multi.run(:action_create, fn %{statement: statement} ->
         Repo.insert(action_create(user_id, video_id, statement))
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
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :update, :statement)
    statement = Repo.get_by!(Statement, id: id, is_removed: false)
    changeset = Statement.changeset(statement, params)
    case changeset.changes do
      changes when changes === %{} ->
        {:reply, :ok, socket}
      _ ->
        action_update = action_update(user_id, video_id, changeset)
        Multi.new
        |> Multi.update(:statement, changeset)
        |> Multi.insert(:action_update, action_update)
        |> Repo.transaction()
        |> case do
          {:ok, %{statement: updated_statement}} ->
            rendered_statement = StatementView.render("show.json", statement: updated_statement)
            broadcast!(socket, "statement_updated", rendered_statement)
            {:reply, :ok, socket}
          {:error, _operation, reason, _changes} ->
            {:reply, {:error, ErrorView.render("error.json", reason: reason)}, socket}
        end
    end
  end

  def handle_in_authenticated!("remove_statement", %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    UserPermissions.check!(user_id, :remove, :statement)
    statement = Repo.get_by!(Statement, id: id, is_removed: false)
    Multi.new
    |> Multi.update(:statement, Statement.changeset_remove(statement))
    |> Multi.run(:action_delete, fn %{statement: statement} ->
         Repo.insert(action_delete(user_id, video_id, statement))
       end)
    |> Repo.transaction()
    |> case do
        {:ok, _} ->
          broadcast!(socket, "statement_removed", %{id: id})
          {:reply, :ok, socket}
        {:error, _, _reason, _} -> {:reply, :error, socket}
    end
  end
end
