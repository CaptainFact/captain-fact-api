use Mix.Config

# --------------------------------------------------------------------------------------
# Prod config / secrets are set at runtime using weave. See `lib/weave.ex`
# --------------------------------------------------------------------------------------

# Do not print debug messages in production
config :logger, level: :info

config :weave,
  file_directory: "/run/secrets",
  loaders: [Weave.Loaders.File, Weave.Loaders.Environment]
