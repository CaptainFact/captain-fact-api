# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :cf_graphql,
  namespace: CF.Graphql,
  ecto_repos: [DB.Repo],
  env: Mix.env(),
  basic_auth: [
    username: "captain",
    password: "SetAtRuntime",
    realm: "GraphiQL Public Endpoint"
  ]

# Configures the endpoint
config :cf_graphql, CF.GraphQLWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Nl5lfMlBMvQpY3n74G9iNTxH4okMpbMWArWst9Vhj75tl+m2PuV+KPwjX0fNMaa8",
  pubsub: [name: CF.Graphql.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Postgres pool size
config :db, DB.Repo, pool_size: 5

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
