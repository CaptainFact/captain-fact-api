use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :cf_atom_feed,
       CF.AtomFeed.Router,
       cowboy: [port: 4004]
