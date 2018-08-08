use Mix.Config

# General config
config :captain_fact, frontend_url: "https://TEST_FRONTEND"

# Don't fetch user picture on test environment
config :captain_fact, fetch_default_user_picture: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :captain_fact, CaptainFactWeb.Endpoint,
  http: [port: 10001],
  server: false,
  force_ssl: false,
  secret_key_base: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"

# Configure Guardian (authentication)
config :captain_fact,
       CaptainFact.Authenticator.GuardianImpl,
       secret_key: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"

# Print only warnings and errors during test
config :logger, level: :warn

# Disable CRON tasks on test
config :captain_fact, CaptainFact.Scheduler, jobs: []

# Mails
config :captain_fact, CaptainFactMailer, adapter: Bamboo.TestAdapter

# Reduce the number of round for encryption during tests
config :bcrypt_elixir, :log_rounds, 4
