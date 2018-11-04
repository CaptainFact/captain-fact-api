use Mix.Config

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

    _ ->
      raise "Invalid bool value: #{inspect(value)}"
  end
end

# ---- [GLOBAL CONFIG] ----

# TODO Erlang cookie

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
  frontend_url: load_secret.("frontend_url"),
  youtube_api_key: load_secret.({"youtube_api_key", nil}),
  oauth: [
    facebook: [
      client_id: load_secret.("facebook_app_id"),
      client_secret: load_secret.("facebook_app_secret"),
      redirect_uri: Path.join(load_secret.("frontend_url"), "/login/callback/facebook")
    ]
  ]

config :cf, CF.Authenticator.GuardianImpl, secret_key: load_secret.("secret_key_base")

# ---- [APP CONFIG] :cf_rest_api ----

if load_bool.({"cors_allow_all", "false"}) do
  config :cf_rest_api, cors_origins: "*"
else
  config :cf_rest_api,
    cors_origins: [
      load_secret.("frontend_url"),
      load_secret.("chrome_extension_id")
    ]
end

config :cf_rest_api, CF.RestApi.Endpoint,
  url: [host: load_secret.("host")],
  secret_key_base: load_secret.("secret_key_base")
