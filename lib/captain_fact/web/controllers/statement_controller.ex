defmodule CaptainFact.Web.StatementController do
  use CaptainFact.Web, :controller

  alias CaptainFact.Web.{Statement, Comment}

  def get(conn, %{"video_id" => video_id}) do
    video_id = CaptainFact.VideoHashId.decode!(video_id)
    statements = Repo.all from statement in Statement,
      left_join: speaker in assoc(statement, :speaker),
      where: statement.video_id == ^video_id,
      where: statement.is_removed == false,
      order_by: statement.time,
      preload: [:speaker, comments: ^(Comment.full(Comment, true))]

    render(conn, "index_full.json", statements: statements)
  end
end
