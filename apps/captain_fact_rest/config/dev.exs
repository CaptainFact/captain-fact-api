use Mix.Config


dev_secret = "8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s"


# For development, we disable any cache and enable
# debugging and code reloading.
config :captain_fact, CaptainFactREST.Endpoint,
  secret_key_base: dev_secret,
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  http: [port: 4000],
  force_ssl: false,
  https: [
    port: 4001,
    otp_app: :captain_fact,
    keyfile: "priv/keys/privkey.pem",
    certfile: "priv/keys/fullchain.pem"
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
