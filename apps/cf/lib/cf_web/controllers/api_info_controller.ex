defmodule CF.Web.ApiInfoController do
  use CF.Web, :controller

  def get(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
      status: "✔",
      version: CF.Application.version(),
      db_version: DB.Application.version()
    })
  end
end
