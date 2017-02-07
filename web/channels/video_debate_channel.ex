defmodule CaptainFact.VideoDebateChannel do
  use CaptainFact.Web, :channel
  alias CaptainFact.Statement
  alias CaptainFact.StatementView

  def join("video_debate:" <> video_id_str, payload, socket) do
    video_id = String.to_integer(video_id_str)
    if authorized?(payload) do
      statements = Repo.all(Statement, video_id: video_id)
      rendered_statements = Phoenix.View.render_many(statements, CaptainFact.StatementView, "statement.json")
      {:ok, rendered_statements, assign(socket, :video_id, video_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Add a new statement
  """
  def handle_in("new_statement", params, socket) do
    # TODO Verify user is owner / admin
    changeset = Statement.changeset(
      %Statement{
        video_id: socket.assigns.video_id,
        status: :voting
      }, params
    )
    case Repo.insert(changeset) do
      {:ok, statement} ->
        socket |>
          broadcast!("new_statement", StatementView.render("show.json", statement: statement))
        {:reply, :ok, socket}
      {:error, reason} ->
        {:reply, :error, socket}
    end
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    # TODO Verify video exists and user is allowed for it (is_private)
    true
  end
end
