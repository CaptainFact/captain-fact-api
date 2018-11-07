defmodule CF.RestApi.StatementView do
  use CF.RestApi, :view

  def render("index.json", %{statements: statements}) do
    render_many(statements, CF.RestApi.StatementView, "statement.json")
  end

  def render("index_full.json", %{statements: statements}) do
    render_many(statements, CF.RestApi.StatementView, "statement_full.json")
  end

  def render("show.json", %{statement: statement}) do
    render_one(statement, CF.RestApi.StatementView, "statement.json")
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
      speaker: render_one(statement.speaker, CF.RestApi.SpeakerView, "speaker.json"),
      comments: render_many(statement.comments, CF.RestApi.CommentView, "comment.json")
    }
  end
end
