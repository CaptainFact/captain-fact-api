use Mix.Config

config :cf_atom_feed, CF.AtomFeed.Router, cowboy: [port: 80]

# Do not print debug messages in production
config :logger, level: :info
