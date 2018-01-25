defmodule DB.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Start by configuring the app with runtime configuration (env + secrets)
    DB.RuntimeConfiguration.setup()
    DB.RuntimeConfiguration.configure()

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: DB.Worker.start_link(arg1, arg2, arg3)
      # worker(DB.Worker, [arg1, arg2, arg3]),
      supervisor(DB.Repo, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DB.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def version() do
    case :application.get_key(:db, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
