defmodule CF.GraphQLWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :cf_graphql

  plug(Plug.RequestId)
  plug(Plug.Logger)

  plug(
    Corsica,
    max_age: 3600,
    allow_headers: ~w(Accept Content-Type Authorization Origin),
    origins: "*"
  )

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(CF.GraphQLWeb.Router)
end
