defmodule CaptainFact.Web.ErrorView do
  use CaptainFact.Web, :view


  def render("show.json", %{message: message}) do
    render_one(message, CaptainFact.Web.ErrorView, "error.json")
  end

  def render("error.json", %{conn: %{status: 401}}) do
    %{error: "unauthorized"}
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end

  def render("error.json", conn) do
    if Mix.env == :dev, do: IO.inspect(conn)
    %{error: "unexpected"}
  end

  def render(_, conn) do
    if Mix.env == :dev, do: IO.inspect(conn)
    %{error: "unexpected"}
  end
end
