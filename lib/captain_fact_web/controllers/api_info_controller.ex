defmodule CaptainFactWeb.ApiInfoController do
  use CaptainFactWeb, :controller

  def get(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
         status: "✔",
         version: api_version()
       })
  end

  defp api_version do
    case :application.get_key(:captain_fact, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
