use Mix.Config

config :captain_fact_atom_feed, CaptainFactAtomFeed.Router, host: "http://localhost:3333"

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n",

