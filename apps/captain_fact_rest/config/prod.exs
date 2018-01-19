use Mix.Config

# --------------------------------------------------------------------------------------
# Prod config / secrets are set at runtime using weave. See `lib/captain_fact/weave.ex`
# --------------------------------------------------------------------------------------

config :captain_fact, CaptainFactREST.Endpoint,
  url: [port: 80],
  http: [port: 80],
  force_ssl: false

# Env / Secrets are above everything else
# Weave loads config from env or secret files
config :weave,
  file_directories: ["/run/secrets"],
  loaders: [Weave.Loaders.File, Weave.Loaders.Environment]
