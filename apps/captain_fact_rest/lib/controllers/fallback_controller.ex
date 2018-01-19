defmodule CaptainFactREST.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use CaptainFactREST, :controller

  alias CaptainFact.Accounts.UserPermissions.PermissionsError

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(CaptainFactREST.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, %PermissionsError{}}) do
    conn
    |> put_status(403)
    |> render(CaptainFactREST.ErrorView, :"403")
  end
end
