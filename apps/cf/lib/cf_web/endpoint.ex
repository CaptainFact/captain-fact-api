defmodule CF.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :cf

  socket("/socket", CF.Web.UserSocket)

  if Application.get_env(:arc, :storage) == Arc.Storage.Local,
    do: plug(Plug.Static, at: "/resources", from: "./resources", gzip: false)

  plug(Plug.RequestId)
  plug(Plug.Logger)
  plug(CF.Web.SecurityHeaders)

  plug(
    Corsica,
    max_age: 3600,
    allow_headers: ~w(Accept Content-Type Authorization Origin),
    origins: {CF.Web.CORS, :check_origin}
  )

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(CF.Web.Router)
end
