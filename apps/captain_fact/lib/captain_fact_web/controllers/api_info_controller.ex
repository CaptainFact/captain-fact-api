defmodule CaptainFactWeb.ApiInfoController do
  use CaptainFactWeb, :controller

  def get(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
         status: "✔",
         version: CaptainFact.Application.version()
       })
  end
end
