use Mix.Config

# Configure Rollbar (errors reporting)
config :rollbax,
  environment: "prod",
  enable_crash_reports: true

# Do not print debug messages in production
config :logger, level: :info
