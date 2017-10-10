# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config


# General application configuration
config :captain_fact,
  ecto_repos: [CaptainFact.Repo],
  source_url_regex: ~r/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/,
  cors_origins: []

# Configures the endpoint
config :captain_fact, CaptainFactWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CaptainFactWeb.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: CaptainFact.PubSub, adapter: Phoenix.PubSub.PG2],
  check_origin: [],
  server: true,
  http: [],
  https: [otp_app: :captain_fact]

# Database: use postgres
config :captain_fact, CaptainFact.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 20

# Configure scheduler
config :captain_fact, CaptainFact.Scheduler,
  jobs: [
    {{:extended,  "*/5 * * * * *"}, {CaptainFact.Actions.Analysers.Votes, :update, []}}, # Every 5 seconds
    {{:cron,      "*/1 * * * *"},   {CaptainFact.Actions.Analysers.Reputation, :update, []}}, # Every minute
    {{:cron,      "*/1 * * * *"},   {CaptainFact.Actions.Analysers.Flags, :update, []}}, # Every minute
    {{:cron,      "*/3 * * * *"},   {CaptainFact.Actions.Analysers.Achievements, :update, []}}, # Every 3 minutes
  ]

# Configure mailer
config :captain_fact, CaptainFact.Mailer, adapter: Bamboo.MailgunAdapter

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure ueberauth
config :ueberauth, Ueberauth,
  base_path: "/api/auth",
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
  serializer: CaptainFactWeb.GuardianSerializer,
  permissions: %{default: [:read, :write]}

config :weave,
  environment_prefix: "CF_",
  loaders: [Weave.Loaders.Environment]

# Import environment specific config
import_config "#{Mix.env}.exs"
