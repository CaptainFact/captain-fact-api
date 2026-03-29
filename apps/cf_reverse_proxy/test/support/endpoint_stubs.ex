defmodule CF.ReverseProxy.EndpointStubs.Rest do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, ~s({"stub":"rest"}))
  end
end

defmodule CF.ReverseProxy.EndpointStubs.Graphql do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, ~s({"stub":"graphql"}))
  end
end

defmodule CF.ReverseProxy.EndpointStubs.Feed do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, ~s({"stub":"feed"}))
  end
end
