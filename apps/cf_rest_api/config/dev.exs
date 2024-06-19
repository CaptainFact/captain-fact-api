use Mix.Config

dev_secret = "8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s"

config :cf_rest_api,
  cors_origins: "*"

# For development, we disable any cache and enable
# debugging and code reloading.
config :cf_rest_api, CF.RestApi.Endpoint,
  secret_key_base: dev_secret,
  debug_errors: false,
  code_reloader: false,
  check_origin: false,
  http: [port: 4000],
  force_ssl: false,
  https: [
    port: 4001,
    otp_app: :cf_rest_api,
    keyfile: "priv/keys/privkey.pem",
    certfile: "priv/keys/fullchain.pem"
  ]

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
config :phoenix, :json_library, Jason
