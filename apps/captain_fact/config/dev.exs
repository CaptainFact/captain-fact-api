use Mix.Config


dev_secret = "8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s"

# General config
config :captain_fact,
  frontend_url: "http://localhost:3333",
  cors_origins: [
    # Self (used by GraphiQL)
    "http://localhost:4000",
    # Frontend Dev
    "http://localhost:3333", "https://localhost:3333",
    "http://192.168.20.6:3333",
    # Overlay injector tester
    "http://localhost:3342",
    # Misc
    "http://localhost", "https://localhost",
    # Extension
    "chrome-extension://fnnhlmbnlbgomamcolcpgncflofhjckm",
  ]

# For development, we disable any cache and enable
# debugging and code reloading.
config :captain_fact, CaptainFactWeb.Endpoint,
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

# Guardian + Ueberauth
config :guardian, Guardian,
  secret_key: dev_secret

config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: "506726596325615",
  client_secret: "4b320056746b8e57144c889f3baf0424"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Mails
config :captain_fact, CaptainFact.Mailer, adapter: Bamboo.LocalAdapter

# Env / Secrets are above everything else
# Weave loads config from env or secret files
config :weave,
       file_directories: ["priv/secrets"],
       loaders: [Weave.Loaders.File, Weave.Loaders.Environment]