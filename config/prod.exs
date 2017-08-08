use Mix.Config

# General config
config :captain_fact, frontend_url: "https://captainfact.io"

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
config :captain_fact, CaptainFactWeb.Endpoint,
  url: [host: "captainfact.io", port: 443],
  force_ssl: [hsts: true],
  http: [
    port: {:system, "PORT"}
  ],
  https: [
    port: 443,
    otp_app: :captain_fact,
    keyfile: System.get_env("SSL_KEY_PATH"),
    certfile: System.get_env("SSL_CERT_PATH")
  ]

# Do not print debug messages in production
config :logger, level: :info

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
#     config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :captain_fact, CaptainFactWeb.Endpoint, server: true
#

