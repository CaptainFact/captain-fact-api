use Mix.Config


# General config
config :captain_fact,
  frontend_url: "https://TEST_FRONTEND",
  # Allow fetching sources from localhost for tests
  source_url_regex: ~r/(^https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*))|localhost/ # TODO [Refactor] Remove

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :captain_fact, CaptainFactWeb.Endpoint,
  http: [port: 4001],
  server: false,
  force_ssl: false,
  secret_key_base: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"

# Configure Guardian (authentication)
config :guardian, Guardian,
  secret_key: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"

# Print only warnings and errors during test
config :logger, level: :warn

# Disable CRON tasks on test
config :captain_fact, CaptainFact.Scheduler, jobs: []

# Mails
config :captain_fact, CaptainFact.Mailer, adapter: Bamboo.TestAdapter