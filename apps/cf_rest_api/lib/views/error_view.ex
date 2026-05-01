defmodule CF.RestApi.ErrorView do
  use CF.RestApi, :view

  require Logger
  alias CF.Accounts.UserPermissions.PermissionsError

  def render("show.json", %{message: message}) do
    render_one(message, CF.RestApi.ErrorView, "error.json")
  end

  def render("401.json", _) do
    %{error: "unauthorized"}
  end

  def render("403.json", %{reason: %PermissionsError{message: message}}) do
    %{error: message}
  end

  def render("403.json", _) do
    %{error: "forbidden"}
  end

  def render("404.json", _) do
    %{error: "not_found"}
  end

  def render("error.json", %{message: message}) do
    %{error: message}
  end

  def render("error.json", _) do
    %{error: "unexpected"}
  end

  def render(other, assigns) do
    Logger.debug(
      "unexpected ErrorView render template=#{inspect(other)} assign_keys=#{inspect(Map.keys(assigns))}"
    )

    %{error: "unexpected"}
  end
end
