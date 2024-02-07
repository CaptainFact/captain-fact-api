defmodule CF.ReverseProxy.Application do
  use Application

  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    port = Application.get_env(:cf_reverse_proxy, :port)

    cowboy =
      {Plug.Cowboy,
       scheme: :http,
       plug: CF.ReverseProxy.Plug,
       port: port,
       dispatch: [
         {:_,
          [
            {"/socket/websocket", Phoenix.Endpoint.Cowboy2Handler, {CF.RestApi.Endpoint, []}},
            {"/socket/longpoll", Phoenix.Endpoint.Cowboy2Handler, {CF.RestApi.Endpoint, []}},
            {:_, Plug.Cowboy.Handler, {CF.ReverseProxy.Plug, []}}
          ]}
       ]}

    Logger.info("Running CF.ReverseProxy with cowboy on port #{port}")
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
