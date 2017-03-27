defmodule CaptainFact.StatementView do
  use CaptainFact.Web, :view

  def render("index.json", %{statements: statements}) do
    render_many(statements, CaptainFact.StatementView, "statement.json")
  end

  def render("show.json", %{statement: statement}) do
    render_one(statement, CaptainFact.StatementView, "statement.json")
  end

  def render("statement.json", %{statement: statement}) do
    %{
      id: statement.id,
      text: statement.text,
      time: statement.time,
      speaker_id: statement.speaker_id
    }
  end
end
