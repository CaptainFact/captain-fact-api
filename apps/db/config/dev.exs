use Mix.Config


# Configure your database
config :db, DB.Repo,
  username: "postgres",
  password: "postgres",
  database: "captain_fact_dev",
  hostname: "localhost"

# Configure file upload
#config :arc, storage: Arc.Storage.Local
