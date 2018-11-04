# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :cf,
  env: Mix.env(),
  ecto_repos: [DB.Repo],
  oauth: [facebook: []],
  invitation_system: false

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

# Configure mailer
config :cf, CF.Mailer, adapter: Bamboo.MailgunAdapter

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Guardian (authentication)
config :cf, CF.Authenticator.Guardian,
  issuer: "CaptainFact",
  ttl: {30, :days},
  serializer: CF.Accounts.GuardianSerializer,
  permissions: %{default: [:read, :write]}

config :cf,
  captions_fetcher: CF.Videos.CaptionsFetcherYoutube

config :guardian, Guardian.DB, repo: DB.Repo

config :weave,
  environment_prefix: "CF_",
  loaders: [Weave.Loaders.Environment]

# Import environment specific config
import_config "#{Mix.env()}.exs"
