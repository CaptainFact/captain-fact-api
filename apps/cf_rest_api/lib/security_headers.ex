defmodule CF.RestApi.SecurityHeaders do
  @x_frame_options if Application.get_env(:cf, :env) == :dev,
                     do: "SAMEORIGIN",
                     else: "DENY"

  def init(params), do: params

  def call(conn, _params) do
    Plug.Conn.merge_resp_headers(conn, [
      {"x-frame-options", @x_frame_options},
      {"x-xss-protection", "1; mode=block"},
      {"x-content-type-options", "nosniff"},
      {"strict-transport-security", "max-age=31536000; includeSubDomains"}
    ])
  end
end
