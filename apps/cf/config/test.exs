use Mix.Config

# General config
config :cf, frontend_url: "https://TEST_FRONTEND"

# Don't fetch user picture on test environment
config :cf, fetch_default_user_picture: false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cf, CF.Web.Endpoint,
  http: [port: 10001],
  server: false,
  force_ssl: false,
  secret_key_base: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"

# Configure Guardian (authentication)
config :cf,
       CF.Authenticator.GuardianImpl,
       secret_key: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"

# Print only warnings and errors during test
config :logger, level: :warn

# Disable CRON tasks on test
config :cf, CF.Scheduler, jobs: []

# Mails
config :cf, CF.Mailer, adapter: Bamboo.TestAdapter

# Reduce the number of round for encryption during tests
config :bcrypt_elixir, :log_rounds, 4

# Captions mock for testing
config :cf,
  captions_fetcher: CF.Videos.CaptionsFetcherTest
