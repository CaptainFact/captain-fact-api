defmodule CF.RestApi.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: CF.RestApi.PubSub},
      # Start the endpoint when the application starts
      supervisor(CF.RestApi.Endpoint, []),
      # Presence to track number of connected users to a channel
      supervisor(CF.RestApi.Presence, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CF.RestApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Get app's version from `mix.exs`
  """
  def version() do
    case :application.get_key(:cf_rest_api, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
