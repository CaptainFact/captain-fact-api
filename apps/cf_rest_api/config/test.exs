use Mix.Config

config :cf_rest_api,
  cors_origins: "*"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :cf_rest_api, CF.RestApi.Endpoint,
  http: [port: 10001],
  server: false,
  force_ssl: false,
  secret_key_base: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"
