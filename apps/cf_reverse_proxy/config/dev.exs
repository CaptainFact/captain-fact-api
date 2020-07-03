use Mix.Config

dev_secret = "8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s"

# For development, we disable any cache and enable
# debugging and code reloading.
config :cf_reverse_proxy, CF.ReverseProxy.Endpoint,
  secret_key_base: dev_secret,
  debug_errors: false,
  code_reloader: false,
  check_origin: false,
  http: [port: 5000],
  force_ssl: false

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
