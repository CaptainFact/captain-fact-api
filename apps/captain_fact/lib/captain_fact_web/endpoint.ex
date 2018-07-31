defmodule CaptainFactWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :captain_fact

  socket("/socket", CaptainFactWeb.UserSocket)

  if Application.get_env(:arc, :storage) == Arc.Storage.Local,
    do: plug(Plug.Static, at: "/resources", from: "./resources", gzip: false)

  plug(Plug.RequestId)
  plug(Plug.Logger)
  plug(CaptainFactWeb.SecurityHeaders)

  plug(
    Corsica,
    max_age: 3600,
    allow_headers: ~w(Accept Content-Type Authorization Origin),
    origins: {CaptainFactWeb.CORS, :check_origin}
  )

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(CaptainFactWeb.Router)
end
