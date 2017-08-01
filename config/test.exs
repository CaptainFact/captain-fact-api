use Mix.Config

# General config
config :captain_fact, frontend_url: "https://TEST_FRONTEND"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :captain_fact, CaptainFactWeb.Endpoint,
  http: [port: 4001],
  server: false,
  force_ssl: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :captain_fact, CaptainFact.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "captain_fact_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# Mails
config :captain_fact, CaptainFact.Mailer, adapter: Bamboo.TestAdapter