use Mix.Config

config :captain_fact_graphql, CaptainFactGraphqlWeb.Endpoint,
  http: [port: 5000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :captain_fact_graphql, CaptainFactGraphql.Repo,
  username: "postgres",
  password: "postgres",
  database: "captain_fact_dev",
  hostname: "localhost",
  pool_size: 5
