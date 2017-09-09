use Mix.Config

# --------------------------------------------------------------------------------------
# Prod config / secrets are set at runtime using weave. See `lib/captain_fact/weave.ex`
# --------------------------------------------------------------------------------------

config :captain_fact, CaptainFactWeb.Endpoint,
  force_ssl: [hsts: true],
  https: [
    keyfile: "/opt/app/ssl-keys/privkey.pem",
    certfile: "/opt/app/ssl-keys/cert.pem"
  ]

# Do not print debug messages in production
config :logger, level: :info

# Env / Secrets are above everything else
# Weave loads config from env or secret files
config :weave,
  file_directories: ["/opt/app/secrets"],
  loaders: [Weave.Loaders.File, Weave.Loaders.Environment]
