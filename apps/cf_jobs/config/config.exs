use Mix.Config

# Configure scheduler
config :cf, CF.Scheduler,
  # Run only one instance across cluster
  global: true,
  debug_logging: false,
  jobs: [
    # credo:disable-for-lines:10
    # Actions analysers
    # Every minute
    {"*/1 * * * *", {CF.Jobs.Reputation, :update, []}},
    # Every day
    {"@daily", {CF.Jobs.Reputation, :reset_daily_limits, []}},
    # Every minute
    {"*/1 * * * *", {CF.Jobs.Flags, :update, []}},
    # Various updaters
    # Every 5 minutes
    {"*/5 * * * *", {CF.Jobs.Moderation, :update, []}}
  ]

# Import environment specific config
import_config "#{Mix.env()}.exs"
