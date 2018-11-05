use Mix.Config

dev_secret = "8C6FsJwjV11d+1WPUIbkEH6gB/VavJrcXWoPLujgpclfxjkLkoNFSjVU9XfeNm6s"

# General config
config :cf,
  frontend_url: "http://localhost:3333",
  oauth: [
    facebook: [
      client_id: "506726596325615",
      client_secret: "4b320056746b8e57144c889f3baf0424",
      redirect_uri: "http://localhost:3333/login/callback/facebook"
    ]
  ]

# Guardian
config :cf,
       CF.Authenticator.GuardianImpl,
       secret_key: dev_secret

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Mails
config :cf, CF.Mailer, adapter: Bamboo.LocalAdapter
