defmodule CaptainFact.Weave do
  @moduledoc """
  Provides runtime configuration using env + secret files
  """
  use Weave

  # ----- Actual configuration -----

  # Global stuff
  weave "frontend_url", handler: fn url -> [
    {:captain_fact, :cors_origins, [url]},
    {:captain_fact, :frontend_url, url},
    {:captain_fact, CaptainFactWeb.Endpoint, [check_origin: [url]]}
  ]
  end
  weave "chrome_extension_id", handler: {:captain_fact, :cors_origins}

  # Endpoint
  weave "host", handler:  fn v -> put_in_endpoint([:url, :host], v) end
  weave "secret_key_base", handler: fn v ->
    put_in_endpoint([:secret_key_base], v)
    put_in_env(:guardian, [Guardian, :secret_key], v)
  end

  # Mailer
  weave "mailgun_domain", handler: fn v -> put_in_mailer([:domain], v) end
  weave "mailgun_api_key", handler: fn v -> put_in_mailer([:api_key], v) end

  # Repo
  weave "db_hostname", handler: fn v -> put_in_repo([:hostname], v) end
  weave "db_username", handler: fn v -> put_in_repo([:username], v) end
  weave "db_password", handler: fn v -> put_in_repo([:password], v) end
  weave "db_name", handler: fn v -> put_in_repo([:database], v) end
  weave "db_pool_size", handler: fn v -> put_in_repo([:pool_size], String.to_integer(v)) end

  # AWS
  weave "s3_access_key_id", handler: fn v -> put_in_env(:ex_aws, [:access_key_id], [v, :instance_role]) end
  weave "s3_secret_access_key", handler: fn v -> put_in_env(:ex_aws, [:secret_access_key], [v, :instance_role]) end

  # Arc storage
  weave "s3_bucket", handler: {:arc, :bucket}

  # Facebook OAUTH
  weave "facebook_app_id", handler: fn v -> put_in_oauth_fb([:client_id], v) end
  weave "facebook_app_secret", handler: fn v -> put_in_oauth_fb([:client_secret], v) end

  # ----- Configuration utils -----

  defp put_in_env(app, [head | keys], value) do
    base = Application.get_env(app, head, [])
    modified = case keys do
      [] -> value
      _ -> put_in(base, keys, value)
    end
    Application.put_env(app, head, modified)
    []
  end

  defp put_in_endpoint(keys, value),
       do: put_in_env(:captain_fact, [CaptainFactWeb.Endpoint] ++ keys, value)
  defp put_in_mailer(keys, value),
       do: put_in_env(:captain_fact, [CaptainFact.Mailer] ++ keys, value)
  defp put_in_repo(keys, value),
       do: put_in_env(:captain_fact, [CaptainFact.Repo] ++ keys, value)
  defp put_in_oauth_fb(keys, value),
       do: put_in_env(:ueberauth, [Ueberauth.Strategy.Facebook.OAuth] ++ keys, value)
end