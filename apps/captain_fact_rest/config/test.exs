use Mix.Config


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :captain_fact, CaptainFactREST.Endpoint,
  http: [port: 4001],
  server: false,
  force_ssl: false,
  secret_key_base: "psZ6n/fq0b444U533yKtve2R0rpjk/IxRGpuanNE92phSDy8/Z2I8lHaIugCMOY7"
