defmodule CaptainFact.StatementsController do
  use CaptainFact.Web, :controller

  alias CaptainFact.{Statement}

  def get(conn, %{"video_id" => video_id}) do
    video_id = CaptainFact.VideoHashId.decode!(video_id)
    statements = from(
      s in Statement,
      where: s.video_id == ^video_id,
      join: c in Comment, on: c.statement_id == s.id
    ) |> Repo.all()
    IO.inspect("OK !")
    IO.inspect(statements)
  end
end
