defmodule CaptainFactREST.ApiInfoController do
  use CaptainFactREST, :controller

  def get(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
         status: "✔",
         version: CaptainFact.version()
       })
  end
end
