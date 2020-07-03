use Mix.Config

config :cf_reverse_proxy, CF.ReverseProxy.Endpoint,
  url: [port: 80],
  http: [port: 80],
  force_ssl: false,
  check_origin: []
