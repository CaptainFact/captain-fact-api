use Mix.Config

config :cf_rest_api,
  cors_origins: []

# Configures the endpoint
config :cf_rest_api, CF.RestApi.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CF.RestApi.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub_server: CF.RestApi.PubSub,
  server: true

# Configure Postgres pool size
config :db, DB.Repo, pool_size: 10

# Import environment specific config
import_config "#{Mix.env()}.exs"
