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
  invitation_system: false,
  soft_limitations_period: 15 * 60,
  hard_limitations_period: 3 * 60 * 60

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

# To send records to Algolia (search engine)
config :algoliax,
  batch_size: 500,
  recv_timeout: 5000,
  application_id: "N5GW2EAIFX"

# Import environment specific config
import_config "#{Mix.env()}.exs"
