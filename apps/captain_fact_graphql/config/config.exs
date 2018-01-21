# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :captain_fact_graphql,
  namespace: CaptainFactGraphql,
  ecto_repos: [DB.Repo],
  env: Mix.env,
  basic_auth: [
    username: "captain",
    password: "Will be replaced by config runtime, see weave.ex",
    realm: "GraphiQL Public Endpoint"
  ]

# Configures the endpoint
config :captain_fact_graphql, CaptainFactGraphqlWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Nl5lfMlBMvQpY3n74G9iNTxH4okMpbMWArWst9Vhj75tl+m2PuV+KPwjX0fNMaa8",
  pubsub: [name: CaptainFactGraphql.PubSub, adapter: Phoenix.PubSub.PG2],
  server: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
