use Mix.Config

# Configure scheduler
config :cf_jobs, CF.Jobs.Scheduler,
  # Run only one instance across cluster
  global: true,
  debug_logging: false,
  jobs: [
    # Reputation
    update_reputations: [
      schedule: {:extended, "*/20"},
      task: {CF.Jobs.Reputation, :update, []},
      overlap: false
    ],
    reset_daily_reputation_limits: [
      schedule: "@daily",
      task: {CF.Jobs.Reputation, :reset_daily_limits, []},
      overlap: false
    ],
    # Moderation
    update_moderation: [
      schedule: "*/5 * * * *",
      task: {CF.Jobs.Moderation, :update, []},
      overlap: false
    ],
    # Flags
    update_flags: [
      schedule: "*/1 * * * *",
      task: {CF.Jobs.Flags, :update, []},
      overlap: false
    ],
    # Notifications
    create_notifications: [
      schedule: {:extended, "*/3"},
      task: {CF.Jobs.CreateNotifications, :update, []},
      overlap: false
    ]
  ]

# Configure Postgres pool size
config :db, DB.Repo, pool_size: 3

# Import environment specific config
import_config "#{Mix.env()}.exs"
