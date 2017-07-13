defmodule CaptainFact.Web.StatementView do
  use CaptainFact.Web, :view

  def render("index.json", %{statements: statements}) do
    render_many(statements, CaptainFact.Web.StatementView, "statement.json")
  end

  def render("index_full.json", %{statements: statements}) do
    render_many(statements, CaptainFact.Web.StatementView, "statement_full.json")
  end

  def render("show.json", %{statement: statement}) do
    render_one(statement, CaptainFact.Web.StatementView, "statement.json")
  end

  def render("statement.json", %{statement: statement}) do
    %{
      id: statement.id,
      text: statement.text,
      time: statement.time,
      speaker_id: statement.speaker_id
    }
  end

  def render("statement_full.json", %{statement: statement}) do
    %{
      id: statement.id,
      text: statement.text,
      time: statement.time,
      speaker: render_one(statement.speaker, CaptainFact.Web.SpeakerView, "speaker.json"),
      comments: render_many(statement.comments, CaptainFact.Web.CommentView, "comment.json")
    }
  end
end
