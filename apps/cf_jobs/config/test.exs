use Mix.Config

# Disable CRON tasks on test
config :cf_jobs, CF.Jobs.Scheduler, jobs: []
