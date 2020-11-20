defmodule ScoutApm.Absinthe.Plug do
  alias ScoutApm.Internal.Layer

  def init(default), do: default

  def call(conn, _default) do
    ScoutApm.TrackedRequest.start_layer("Controller", action_name(conn))

    conn
    |> Plug.Conn.register_before_send(&before_send/1)
  end

  def before_send(conn) do
    full_name = action_name(conn)
    uri = "#{conn.request_path}"

    ScoutApm.TrackedRequest.stop_layer(fn layer ->
      layer
      |> Layer.update_name(full_name)
      |> Layer.update_uri(uri)
    end)

    conn
  end

  # Takes a connection, extracts the phoenix controller & action, then manipulates & cleans it up.
  # Returns a string like "PageController#index"
  defp action_name(conn) do
    action_name = conn.params["operationName"]
    "GraphQL##{action_name}"
  end
end
