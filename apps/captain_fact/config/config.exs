# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :captain_fact,
  env: Mix.env(),
  ecto_repos: [DB.Repo],
  cors_origins: [],
  oauth: [facebook: []],
  invitation_system: false

# Configures the endpoint
config :captain_fact, CaptainFactWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CaptainFactWeb.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: CaptainFact.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true

# Configure scheduler
config :captain_fact, CaptainFact.Scheduler,
  # Run only one instance across cluster
  global: true,
  debug_logging: false,
  jobs: [
    # credo:disable-for-lines:10
    # Actions analysers
    # Every 5 seconds
    {{:extended, "*/5 * * * * *"}, {CaptainFactJobs.Votes, :update, []}},
    # Every minute
    {"*/1 * * * *", {CaptainFactJobs.Reputation, :update, []}},
    # Every day
    {"@daily", {CaptainFactJobs.Reputation, :reset_daily_limits, []}},
    # Every minute
    {"*/1 * * * *", {CaptainFactJobs.Flags, :update, []}},
    # Every 3 minutes
    {"*/3 * * * *", {CaptainFactJobs.Achievements, :update, []}},
    # Various updaters
    # Every 5 minutes
    {"*/5 * * * *", {CaptainFactJobs.Moderation, :update, []}}
  ]

# Configure mailer
config :captain_fact, CaptainFactMailer, adapter: Bamboo.MailgunAdapter

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Guardian (authentication)
config :captain_fact, CaptainFact.Authenticator.Guardian,
  issuer: "CaptainFact",
  ttl: {30, :days},
  serializer: CaptainFact.Accounts.GuardianSerializer,
  permissions: %{default: [:read, :write]}

config :guardian, Guardian.DB, repo: DB.Repo

config :weave,
  environment_prefix: "CF_",
  loaders: [Weave.Loaders.Environment]

# Import environment specific config
import_config "#{Mix.env()}.exs"
