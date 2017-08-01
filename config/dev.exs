use Mix.Config

# General config
config :captain_fact, frontend_url: "http://localhost:3333"

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :captain_fact, CaptainFactWeb.Endpoint,
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: [],
  http: [port: 4000],
  force_ssl: false,
  https: [
    port: 4001,
    otp_app: :captain_fact,
    keyfile: "priv/keys/localhost.key",
    certfile: "priv/keys/localhost.cert"
  ]

# Watch static and templates for browser reloading.
config :captain_fact, CaptainFactWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/captain_fact/web/views/.*(ex)$},
      ~r{lib/captain_fact/web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Configure your database
config :captain_fact, CaptainFact.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "captain_fact_dev",
  hostname: "localhost",
  pool_size: 10

# Mails
config :captain_fact, CaptainFact.Mailer, adapter: Bamboo.LocalAdapter