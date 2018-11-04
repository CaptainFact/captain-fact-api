use Mix.Config

# Disable CRON tasks on test
config :cf, CF.Scheduler, jobs: []
