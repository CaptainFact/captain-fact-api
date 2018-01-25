defmodule CaptainFactGraphql.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Start by configuring the app with runtime configuration (env + secrets)
    CaptainFactGraphql.RuntimeConfiguration.setup()
    CaptainFactGraphql.RuntimeConfiguration.configure()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(CaptainFactGraphqlWeb.Endpoint, []),
      # Start your own worker by calling: CaptainFactGraphql.Worker.start_link(arg1, arg2, arg3)
      # worker(CaptainFactGraphql.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CaptainFactGraphql.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CaptainFactGraphqlWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def version() do
    case :application.get_key(:captain_fact_graphql, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
