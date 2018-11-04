use Mix.Config

config :cf_rest_api,
  cors_origins: []

# Configures the endpoint
config :cf_rest_api, CF.RestApi.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CF.RestApi.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: CF.RestApi.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true

# Import environment specific config
import_config "#{Mix.env()}.exs"
