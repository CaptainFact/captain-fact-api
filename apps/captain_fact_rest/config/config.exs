use Mix.Config

# Configures the endpoint
config :captain_fact, CaptainFactREST.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CaptainFactREST.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: CaptainFact.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true

# Import environment specific config
import_config "#{Mix.env}.exs"
