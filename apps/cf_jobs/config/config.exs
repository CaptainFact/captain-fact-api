use Mix.Config

# Configure scheduler
config :cf_jobs, CF.Jobs.Scheduler,
  # Run only one instance across cluster
  global: true,
  debug_logging: false,
  jobs: [
    # credo:disable-for-lines:10
    # Actions analysers
    # Every minute
    {{:extended, "*/20"}, {CF.Jobs.Reputation, :update, []}},
    # Every day
    {"@daily", {CF.Jobs.Reputation, :reset_daily_limits, []}},
    # Every minute
    {"*/1 * * * *", {CF.Jobs.Flags, :update, []}},
    # Various updaters
    # Every 5 minutes
    {"*/5 * * * *", {CF.Jobs.Moderation, :update, []}}
  ]

# Configure Postgres pool size
config :db, DB.Repo, pool_size: 3

# Import environment specific config
import_config "#{Mix.env()}.exs"
