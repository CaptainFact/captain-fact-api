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
  cors_origins: ["http://localhost:3333", "chrome-extension://lpdmcoikcclagelhlmibniibjilfifac"]

# Configures the endpoint
config :captain_fact, CaptainFactWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CaptainFactWeb.ErrorView, accepts: ~w(json), default_format: "json"],
  pubsub: [name: CaptainFact.PubSub, adapter: Phoenix.PubSub.PG2]

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

# Configure file upload
config :arc, storage: Arc.Storage.Local

# Configure scheduler
config :quantum, :captain_fact,
  cron: [
    # Reset score limit counter at midnight
    "@daily": {CaptainFact.Accounts.UserState, :reset, []}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
