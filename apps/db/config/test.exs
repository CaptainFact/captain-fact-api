use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

# Configure file upload
config :arc, storage: Arc.Storage.Local

# Configure your database
config :db, DB.Repo,
  hostname:
    if(
      is_nil(System.get_env("CF_DB_HOSTNAME")),
      do: "localhost",
      else: System.get_env("CF_DB_HOSTNAME")
    ),
  username: "postgres",
  password: "postgres",
  database: "captain_fact_test",
  pool: Ecto.Adapters.SQL.Sandbox
