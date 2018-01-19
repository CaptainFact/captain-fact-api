defmodule CaptainFactGraphql.Endpoint do
  use Phoenix.Endpoint, otp_app: :captain_fact_graphql

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head
  plug CaptainFactGraphql.Router
end
