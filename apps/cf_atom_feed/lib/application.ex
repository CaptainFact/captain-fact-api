defmodule CF.AtomFeed.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    children = []
    config = Application.get_env(:cf_atom_feed, CF.AtomFeed.Router)

    if config[:cowboy] do
      children = [supervisor(CF.AtomFeed.Router, []) | children]
    end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CF.AtomFeed.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(_changed, _new, _removed) do
    :ok
  end

  def version() do
    case :application.get_key(:cf_atom_feed, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
