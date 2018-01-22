# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config


# General application configuration
config :captain_fact,
  env: Mix.env,
  ecto_repos: [DB.Repo],
  cors_origins: []

# Configures the endpoint
config :captain_fact, CaptainFactWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CaptainFactWeb.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: CaptainFact.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true

# Configure scheduler
config :captain_fact, CaptainFact.Scheduler,
  global: true,
  jobs: [
    # Actions analysers
    {{:extended, "*/5 * * * * *"}, {CaptainFact.Actions.Analyzers.Votes, :update, []}}, # Every 5 seconds
    {            "*/1 * * * *",    {CaptainFact.Actions.Analyzers.Reputation, :update, []}}, # Every minute
    {            "@daily",         {CaptainFact.Actions.Analyzers.Reputation, :reset_daily_limits, []}}, # Every day
    {            "*/1 * * * *",    {CaptainFact.Actions.Analyzers.Flags, :update, []}}, # Every minute
    {            "*/3 * * * *",    {CaptainFact.Actions.Analyzers.Achievements, :update, []}}, # Every 3 minutes
    # Various updaters
    {            "*/20 * * * *",   {CaptainFact.Moderation.Updater, :update, []}}, # Every 20 minutes
  ]

# Configure mailer
config :captain_fact, CaptainFact.Mailer, adapter: Bamboo.MailgunAdapter

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure ueberauth
config :ueberauth, Ueberauth,
  base_path: "/auth",
  providers: [
    identity: {Ueberauth.Strategy.Identity, [callback_methods: ["POST"]]},
    facebook: {Ueberauth.Strategy.Facebook, [
      callback_methods: ["POST"],
      profile_fields: "name,email,picture"
    ]}
  ]

# Configure Guardian (authentication)
config :guardian, Guardian,
  issuer: "CaptainFact",
  ttl: {30, :days},
  serializer: CaptainFact.Accounts.GuardianSerializer,
  permissions: %{default: [:read, :write]}

config :weave,
  environment_prefix: "CF_",
  loaders: [Weave.Loaders.Environment]

# Import environment specific config
import_config "#{Mix.env}.exs"
