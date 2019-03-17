defmodule CF.Graphql.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(CF.GraphQLWeb.Endpoint, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CF.Graphql.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CF.GraphQLWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def version() do
    case :application.get_key(:cf_graphql, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
