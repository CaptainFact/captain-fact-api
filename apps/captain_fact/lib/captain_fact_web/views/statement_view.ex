defmodule CaptainFactWeb.StatementView do
  use CaptainFactWeb, :view

  def render("index.json", %{statements: statements}) do
    render_many(statements, CaptainFactWeb.StatementView, "statement.json")
  end

  def render("index_full.json", %{statements: statements}) do
    render_many(statements, CaptainFactWeb.StatementView, "statement_full.json")
  end

  def render("show.json", %{statement: statement}) do
    render_one(statement, CaptainFactWeb.StatementView, "statement.json")
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
      speaker: render_one(statement.speaker, CaptainFactWeb.SpeakerView, "speaker.json"),
      comments: render_many(statement.comments, CaptainFactWeb.CommentView, "comment.json")
    }
  end
end
