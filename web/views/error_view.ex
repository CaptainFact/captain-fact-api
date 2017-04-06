defmodule CaptainFact.ErrorView do
  use CaptainFact.Web, :view

  def render("show.json", %{message: message}) do
    render_one(message, CaptainFact.ErrorView, "error.json")
  end

  def render("400.json", error) do
    IO.inspect(error)
    %{errors: [%{message: "Bad Request"}]}
  end

  def render("401.json", _) do
    %{errors: [%{message: "You are not authorized to access this resource"}]}
  end

  def render("404.json", _) do
    %{errors: [%{message: "Not Found"}]}
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  def render("500.json", _) do
    %{errors: [%{message: "Server encountered an unexpected error. We're working on it !"}]}
  end

  def render("error.json", %{message: message}) do
    %{
      errors: [message]
    }
  end

  def render("error.json", _) do
    %{
      errors: ["Unknow error"]
    }
  end

  def render(_, error) do
    IO.inspect(error)
    "Unknow error"
  end
end
