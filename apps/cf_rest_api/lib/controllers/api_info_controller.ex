defmodule CF.RestApi.ApiInfoController do
  use CF.RestApi, :controller

  # Mix is not available at runtime in OTP releases; bake env at compile time.
  @mix_env Mix.env()

  def get(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{
      app: "CF.RestApi",
      status: "✔",
      version: CF.Application.version(),
      db_version: DB.Application.version(),
      env: Application.get_env(:cf, :deploy_env),
      host: Application.get_env(:cf, :host),
      mix_env: @mix_env
    })
  end
end
