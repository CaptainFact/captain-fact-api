import Config

# Configure your database (CF_DB_HOSTNAME defaults to localhost; devcontainer sets "database")
config :db, DB.Repo,
  hostname:
    if(
      is_nil(System.get_env("CF_DB_HOSTNAME")),
      do: "localhost",
      else: System.get_env("CF_DB_HOSTNAME")
    ),
  username: "postgres",
  password: "postgres",
  database: "captain_fact_dev"

# Configure file upload
config :arc, storage: Arc.Storage.Local, asset_host: "http://localhost:4000"
