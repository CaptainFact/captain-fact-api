import Config

# ---- Helpers ----

# Try to load `secret_name` from `/run/secrets/secret_name`.
# If it fails, fallback to load it from env variable `CF_SECRET_NAME`.
# If it fails too, fallback on `default`.
do_load_secret = fn secret_name ->
  cond do
    File.exists?("/run/secrets/#{secret_name}") ->
      File.read!("/run/secrets/#{secret_name}")

    System.get_env("CF_#{String.upcase(secret_name)}") ->
      System.get_env("CF_#{String.upcase(secret_name)}")

    true ->
      nil
  end
end

load_secret = fn
  {secret_name, default} ->
    do_load_secret.(secret_name) || default

  secret_name ->
    do_load_secret.(secret_name) || ""
end

load_bool = fn secret ->
  case String.downcase(load_secret.(secret)) do
    value when value in ~w(yes true on) ->
      true

    value when value in ~w(no false off) ->
      false

    value ->
      raise "Invalid bool value: #{inspect(value)}"
  end
end

load_int = fn secret ->
  case load_secret.(secret) do
    value when is_integer(value) ->
      value

    value when is_binary(value) ->
      case Integer.parse(value) do
        {number, ""} -> number
        _ -> 0
      end

    _ ->
      0
  end
end

# ---- [Global config keys] ----

frontend_url = String.trim_trailing(load_secret.("frontend_url")) <> "/"
rollbar_access_token = load_secret.({"rollbar_access_token", nil})

if rollbar_access_token do
  config :rollbax,
    enabled: true,
    access_token: rollbar_access_token,
    environment: load_secret.({"rollbar_environment", "production"})
end

# ---- [APP CONFIG] :db ----

config :db, DB.Repo,
  hostname: load_secret.("db_hostname"),
  username: load_secret.("db_username"),
  password: load_secret.("db_password"),
  database: load_secret.("db_name")

config :ex_aws,
  access_key_id: [load_secret.("s3_access_key_id"), :instance_role],
  secret_access_key: [load_secret.("s3_secret_access_key"), :instance_role]

config :arc,
  bucket: load_secret.("s3_bucket")

# ---- [APP CONFIG] :cf ----

config :cf,
  frontend_url: frontend_url,
  soft_limitations_period: load_int.({"soft_limitations_period", 15 * 60}),
  hard_limitations_period: load_int.({"hard_limitations_period", 3 * 60 * 60}),
  invitation_system: load_bool.({"invitation_system", "false"}),
  youtube_api_key: load_secret.({"youtube_api_key", nil}),
  oauth: [
    facebook: [
      client_id: load_secret.("facebook_app_id"),
      client_secret: load_secret.("facebook_app_secret"),
      redirect_uri: Path.join(frontend_url, "login/callback/facebook")
    ]
  ]

config :cf, CF.Authenticator.GuardianImpl, secret_key: load_secret.("secret_key_base")

config :cf, CF.Mailer,
  domain: load_secret.("mailgun_domain"),
  api_key: load_secret.("mailgun_api_key")

# ---- [APP CONFIG] :cf_rest_api ----

cors_allow_all? = load_bool.({"cors_allow_all", "false"})
check_origin = if cors_allow_all?, do: false, else: [frontend_url]

config :cf_rest_api, CF.RestApi.Endpoint,
  url: [host: load_secret.("host")],
  secret_key_base: load_secret.("secret_key_base"),
  check_origin: check_origin

# CORS origins for HTTP endpoint

if cors_allow_all? do
  config :cf_rest_api, cors_origins: "*"
else
  config :cf_rest_api,
    cors_origins: [
      String.trim_trailing(frontend_url, "/"),
      load_secret.("chrome_extension_id")
    ]
end

# ---- [APP CONFIG] :cf_graphql ----

config :cf_graphql, CF.GraphQLWeb.Endpoint,
  url: [host: load_secret.("host")],
  secret_key_base: [host: load_secret.("secret_key_base")]

# ---- [APP CONFIG] :cf_reverse_proxy ----

config :cf_reverse_proxy, CF.ReverseProxy.Endpoint,
  check_origin: false,
  url: [
    host: System.get_env("RENDER_EXTERNAL_HOSTNAME") || load_secret.("host") || "localhost",
    port: load_int.("port")
  ]
