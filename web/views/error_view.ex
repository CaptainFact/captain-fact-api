defmodule CaptainFact.ErrorView do
  use CaptainFact.Web, :view

  alias CaptainFact.UserPermissions.PermissionsError

  def render("show.json", %{message: message}) do
    render_one(message, CaptainFact.ErrorView, "error.json")
  end

  def render("400.json", errors) do
    if Mix.env == :dev, do: IO.inspect(errors)
    %{errors: [%{message: "Bad Request"}]}
  end

  def render("401.json", _) do
    %{errors: [%{message: "You are not authorized to access this resource"}]}
  end

  def render("403.json", %{reason: %PermissionsError{message: message}}) do
    %{errors: %{message: message}}
  end

  def render("403.json", errors) do
    if Mix.env == :dev, do: IO.inspect(errors)
    %{errors: %{message: "You are not authorized to access this resource"}}
  end

  def render("404.json", errors) do
    if Mix.env == :dev, do: IO.inspect(errors)
    %{errors: [%{message: "Not Found"}]}
  end

  def render("500.html", errors) do
    if Mix.env == :dev, do: IO.inspect(errors)
    "Internal server error"
  end

  def render("500.json", errors) do
    if Mix.env == :dev, do: IO.inspect(errors)
    %{errors: [%{message: "Server encountered an unexpected error. We're working on it !"}]}
  end

  def render("error.json", %{message: message}) do
    if Mix.env == :dev, do: IO.inspect(message)
    %{
      errors: [message]
    }
  end

  def render("error.json", error) do
    if Mix.env == :dev, do: IO.inspect(error)
    %{
      errors: ["Server encountered an unexpected error. We're working on it !"]
    }
  end

  def render(_, error) do
    if Mix.env == :dev, do: IO.inspect(error)
    "Server encountered an unexpected error. We're working on it !"
  end
end
