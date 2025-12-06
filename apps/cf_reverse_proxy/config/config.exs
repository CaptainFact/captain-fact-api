import Config

# Configures the endpoint
config :cf_reverse_proxy, port: 5000

# Import environment specific config
Config.import_config("#{Mix.env()}.exs")
