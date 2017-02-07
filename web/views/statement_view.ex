defmodule CaptainFact.StatementView do
  use CaptainFact.Web, :view

  def render("show.json", %{statement: statement}) do
    render_one(statement, CaptainFact.StatementView, "statement.json")
  end

  def render("statement.json", %{statement: statement}) do
    %{
      id: statement.id,
      text: statement.text,
      time: statement.time
    }
  end
end
