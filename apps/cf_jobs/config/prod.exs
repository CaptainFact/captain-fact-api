use Mix.Config

# --------------------------------------------------------------------------------------
# Prod config / secrets are set at runtime using weave.
# See `lib/captain_fact/weave.ex`
# --------------------------------------------------------------------------------------

# Do not print debug messages in production
config :logger, level: :info

# Env / Secrets are above everything else
# Weave loads config from env or secret files
config :weave,
  file_directory: "/run/secrets",
  loaders: [Weave.Loaders.File, Weave.Loaders.Environment]
