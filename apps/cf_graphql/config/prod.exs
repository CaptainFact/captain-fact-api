use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

# Configure endpoint
config :cf_graphql, CF.GraphQLWeb.Endpoint,
  server: false,
  debug_errors: false,
  code_reloader: false,
  check_origin: false,
  watchers: [],
  # Avoid logging every rendered error (telemetry still carries :conn; lowering
  # log helps, and :accepts fixes the common NotAcceptable noise from browsers).
  render_errors: [
    view: Phoenix.ErrorView,
    accepts: ~w(html json),
    layout: false,
    log: false
  ]
