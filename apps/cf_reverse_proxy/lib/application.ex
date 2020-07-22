defmodule CF.ReverseProxy.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    port = Application.get_env(:cf_reverse_proxy, :port)

    websocket =
      {Phoenix.Transports.WebSocket, {CF.RestApi.Endpoint, CF.RestApi.UserSocket, :websocket}}

    cowboy_options = [
      port: port,
      dispatch: [
        {:_,
         [
           {"/socket/websocket", Phoenix.Endpoint.CowboyWebSocket, websocket},
           {:_, Plug.Adapters.Cowboy.Handler, {CF.ReverseProxy.Plug, []}}
         ]}
      ]
    ]

    cowboy = Plug.Adapters.Cowboy.child_spec(:http, CF.ReverseProxy.Plug, [], cowboy_options)
    opts = [strategy: :one_for_one, name: CF.ReverseProxy.Supervisor]
    Supervisor.start_link([cowboy], opts)
  end

  def config_change(_changed, _new, _removed) do
    :ok
  end

  def version() do
    case :application.get_key(:cf_reverse_proxy, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
