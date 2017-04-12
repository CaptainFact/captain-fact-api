defmodule CaptainFact.StatementsChannel do
  use CaptainFact.Web, :channel

  alias CaptainFact.Statement
  alias CaptainFact.StatementView
  alias CaptainFact.ErrorView
  alias CaptainFact.VideoHashId


  def join("statements:video:" <> video_id_hash, _payload, socket) do
    video_id = VideoHashId.decode!(video_id_hash)
    socket = assign(socket, :video_id, video_id)
    # TODO store public user in socket
    # TODO verify user has_access
    # TODO user is admin
    statements = Statement
    |> where(video_id: ^video_id)
    |> Repo.all

    rendered_statements = StatementView.render("index.json", statements: statements)
    {:ok, rendered_statements, socket}
  end

  @doc """
  Add a new statement
  """
  def handle_in("new_statement", params, socket) do
    changeset = Statement.changeset(
      %Statement{
        video_id: socket.assigns.video_id,
      }, params
    )
    case Repo.insert(changeset) do
      {:ok, statement} ->
        broadcast!(socket, "statement_added", StatementView.render("show.json", statement: statement))
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, ErrorView.render("error.json", reason: reason)}, socket}
    end
  end

  def handle_in("update_statement", params, socket) do
    statement = Repo.get!(Statement, params["id"])
    changeset = Statement.changeset(statement, params)
    case Repo.update(changeset) do
      {:ok, statement} ->
        broadcast!(socket, "statement_updated", StatementView.render("show.json", statement: statement))
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, {:error, ErrorView.render("error.json", reason: reason)}, socket}
    end
  end

  def handle_in("delete_statement", %{"id" => id}, socket) do
    Statement
    |> where(id: ^id)
    |> Repo.delete_all()
    broadcast!(socket, "statement_deleted", %{id: id})
    {:reply, :ok, socket}
  end
end
