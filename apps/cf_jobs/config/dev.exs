use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Env / Secrets are above everything else
# Weave loads config from env or secret files
config :weave, loaders: [Weave.Loaders.File, Weave.Loaders.Environment]
