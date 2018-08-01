use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

# Use a different port in test to avoid conflicting with dev server
config :cf_atom_feed, CF.AtomFeed.Router, cowboy: [port: 10004]
