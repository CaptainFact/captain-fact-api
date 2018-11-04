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
    {"*/1 * * * *", {CF.Jobs.Reputation, :update, []}},
    # Every day
    {"@daily", {CF.Jobs.Reputation, :reset_daily_limits, []}},
    # Every minute
    {"*/1 * * * *", {CF.Jobs.Flags, :update, []}},
    # Various updaters
    # Every 5 minutes
    {"*/5 * * * *", {CF.Jobs.Moderation, :update, []}}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :weave,
  environment_prefix: "CF_",
  loaders: [Weave.Loaders.Environment]

# Import environment specific config
import_config "#{Mix.env()}.exs"
