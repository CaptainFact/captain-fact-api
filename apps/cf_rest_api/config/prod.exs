use Mix.Config

config :cf, CF.RestApi.Endpoint,
  url: [port: 80],
  http: [port: 80],
  force_ssl: false,
  check_origin: []
