use Mix.Config

# Disable CRON tasks during tests
config :cf, CF.Scheduler, jobs: []
