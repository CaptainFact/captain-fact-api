use Mix.Config

# Configures the endpoint
config :cf, CF.RestApi.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CF.RestApi.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: CF.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true

# Import environment specific config
import_config "#{Mix.env()}.exs"
