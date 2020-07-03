defmodule CF.ReverseProxy.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec
    children = [supervisor(CF.ReverseProxy.Endpoint, [])]
    opts = [strategy: :one_for_one, name: CF.ReverseProxy.Supervisor]
    Supervisor.start_link(children, opts)
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
