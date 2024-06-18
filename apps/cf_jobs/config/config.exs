use Mix.Config

# Configure scheduler
config :cf_jobs, CF.Jobs.Scheduler,
  # Run only one instance across cluster
  global: true,
  debug_logging: false,
  jobs: [
    # Reputation
    update_reputations: [
      # every 20 minutes
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
      # every 5 minutes
      schedule: "*/5 * * * *",
      task: {CF.Jobs.Moderation, :update, []},
      overlap: false
    ],
    # Flags
    update_flags: [
      # every minute
      schedule: "*/1 * * * *",
      task: {CF.Jobs.Flags, :update, []},
      overlap: false
    ],
    # Notifications
    create_notifications: [
      # every 5 seconds
      schedule: {:extended, "*/5"},
      task: {CF.Jobs.CreateNotifications, :update, []},
      overlap: false
    ],
    # Captions
    download_captions: [
      # every 10 minutes
      schedule: "*/10 * * * *",
      task: {CF.Jobs.DownloadCaptions, :update, []},
      overlap: false
    ]
  ]

# Configure Postgres pool size
config :db, DB.Repo, pool_size: 3

# Import environment specific config
import_config "#{Mix.env()}.exs"
