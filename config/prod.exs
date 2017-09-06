use Mix.Config

# General config
config :captain_fact,
       frontend_url: "${FRONTEND_URL}",
       cors_origins: ["${FRONTEND_URL}", "${CHROME_EXTENSION_ID}"]

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
config :captain_fact, CaptainFactWeb.Endpoint,
  url: [host: "${HOST}", port: "${PORT}"],
  check_origin: ["${FRONTEND_URL}"],
  secret_key_base: "${SECRET_KEY_BASE}",
  server: true,
  http: [port: "${PORT}"],
  https: [
    port: "${PORT_SSL}",
    otp_app: :captain_fact,
    keyfile: "${SSL_KEY_PATH}",
    certfile: "${SSL_CERT_PATH}"
  ],
  force_ssl: [hsts: true]

# Mails
config :captain_fact, CaptainFact.Mailer,
  adapter: Bamboo.MailgunAdapter,
  domain: "${MAILGUN_DOMAIN}",
  api_key: "${MAILGUN_API_KEY}"

config :guardian, Guardian,
  secret_key: "${SECRET_KEY_BASE}"

config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: "${FACEBOOK_APP_ID}",
  client_secret: "${FACEBOOK_APP_SECRET}"

config :captain_fact, CaptainFact.Repo,
  adapter: Ecto.Adapters.Postgres,
  hostname: "${DB_HOSTNAME}",
  username: "${DB_USERNAME}",
  password: "${DB_PASSWORD}",
  database: "${DB_NAME}",
  pool_size: 20

config :arc, storage: Arc.Storage.S3, bucket: "${S3_BUCKET}"

config :ex_aws,
       access_key_id: ["${S3_ACCESS_KEY_ID}", :instance_role],
       secret_access_key: ["${S3_SECRET_ACCESS_KEY}", :instance_role]

# Do not print debug messages in production
config :logger, level: :info
