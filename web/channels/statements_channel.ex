defmodule CaptainFact.StatementsChannel do
  use CaptainFact.Web, :channel

  alias Ecto.Multi

  alias CaptainFact.Statement
  alias CaptainFact.StatementView
  alias CaptainFact.ErrorView
  alias CaptainFact.VideoHashId

  import CaptainFact.VideoDebateActionCreator, only: [
    action_create: 3, action_update: 3, action_delete: 3
  ]


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
    case socket.assigns.user_id do
      nil -> {:reply, :error, socket}
      _ -> handle_in_authentified(command, params, socket)
    end
  end

  @doc """
  Add a new statement
  """
  def handle_in_authentified("new_statement", params, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    changeset = Statement.changeset(%Statement{video_id: video_id}, params)
    Multi.new
    |> Multi.insert(:statement, changeset)
    |> Multi.run(:action_create, fn %{statement: statement} ->
        Repo.insert(action_create(user_id, video_id, statement))
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{statement: statement}} ->
        broadcast!(socket, "statement_added", StatementView.render("show.json", statement: statement))
        {:reply, :ok, socket}
      {:error, _operation, reason, _changes} ->
        {:reply, {:error, ErrorView.render("error.json", reason: reason)}, socket}
    end
  end

  def handle_in_authentified("update_statement", params = %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
    statement = Repo.get_by!(Statement, id: id, is_removed: false)
    changeset = Statement.changeset(statement, params)
    case changeset.changes do
      changes when changes === %{} -> {:reply, :ok, socket}
      changes ->
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

  def handle_in_authentified("delete_statement", %{"id" => id}, socket) do
    %{user_id: user_id, video_id: video_id} = socket.assigns
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
