use Mix.Config

# Configure Postgres pool size
config :db, DB.Repo, pool_size: 1

import_config "#{Mix.env()}.exs"
