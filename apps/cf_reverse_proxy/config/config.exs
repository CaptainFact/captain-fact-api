use Mix.Config

# Configures the endpoint
config :cf_reverse_proxy, CF.ReverseProxy.Endpoint,
  url: [host: "localhost"],
  http: [port: 5000],
  server: true

# Import environment specific config
import_config "#{Mix.env()}.exs"
