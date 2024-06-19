use Mix.Config

# General application configuration
config :db,
  env: Mix.env(),
  ecto_repos: [DB.Repo]

# Database: use postgres
config :db, DB.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: 3,
  loggers: [
    {Ecto.LogEntry, :log, []}
  ]

# Import environment specific config
import_config "#{Mix.env()}.exs"
