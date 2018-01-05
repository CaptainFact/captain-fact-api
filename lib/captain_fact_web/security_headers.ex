defmodule CaptainFactWeb.SecurityHeaders do
  def init(params), do: params

  def call(conn, _params) do
    Plug.Conn.merge_resp_headers(conn, [
      {"x-frame-options", "DENY"},
      {"x-xss-protection", "1; mode=block"},
      {"x-content-type-options", "nosniff"},
      {"strict-transport-security", "max-age=31536000; includeSubDomains"},
    ])
  end
end