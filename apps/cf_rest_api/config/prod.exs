use Mix.Config

config :cf_rest_api, CF.RestApi.Endpoint,
  force_ssl: false,
  check_origin: [],
  server: false
