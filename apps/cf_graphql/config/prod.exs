use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

# Configure endpoint
config :cf_graphql, CF.GraphQLWeb.Endpoint,
  http: [port: 80],
  debug_errors: false,
  code_reloader: false,
  check_origin: false,
  watchers: []
