use Mix.Config

config :captain_fact_atom_feed, CaptainFactAtomFeed.Router, cowboy: [port: 80], host: "https://www.captainfact.io"

config :db, DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 2

# Do not print debug messages in production
config :logger, level: :info
