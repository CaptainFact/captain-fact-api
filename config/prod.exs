use Mix.Config

# --------------------------------------------------------------------------------------
# Prod config / secrets are set at runtime using weave. See `lib/captain_fact/weave.ex`
# --------------------------------------------------------------------------------------

config :captain_fact, CaptainFactWeb.Endpoint,
  url: [port: 80],
  http: [port: 80],
  https: [
    port: 443,
    keyfile: "/run/secrets/privkey.pem",
    certfile: "/run/secrets/cert.pem"
  ]

# Do not print debug messages in production
config :logger, level: :info

# Env / Secrets are above everything else
# Weave loads config from env or secret files
config :weave,
  file_directories: ["/run/secrets"],
  loaders: [Weave.Loaders.File, Weave.Loaders.Environment]
