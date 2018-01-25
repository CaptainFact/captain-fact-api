use Mix.Config


config :captain_fact_graphql, CaptainFactGraphqlWeb.Endpoint,
  http: [port: 5000],
  https: [
    port: 5001,
    otp_app: :captain_fact_graphql,
    keyfile: "priv/keys/privkey.pem",
    certfile: "priv/keys/fullchain.pem"
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
