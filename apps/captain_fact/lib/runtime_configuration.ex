defmodule CaptainFact.RuntimeConfiguration do
  @moduledoc """
  Provides runtime configuration using env + secret files
  """
  use Weave
  require Logger

  def setup() do
    secrets_path =
      if File.exists?("/run/secrets"),
        do: "/run/secrets",
        else: Path.join(:code.priv_dir(:captain_fact), "secrets")

    Application.put_env(:weave, :file_directory, secrets_path)

    Application.put_env(:weave, :only, [
      "frontend_url",
      "chrome_extension_id",
      "host",
      "secret_key_base",
      "mailgun_domain",
      "mailgun_api_key",
      "facebook_app_id",
      "facebook_app_secret",
      "youtube_api_key",
      "erlang_cookie",
      "cors_allow_all"
    ])
  end

  # ----- Actual configuration -----

  # Global stuff
  weave(
    "frontend_url",
    handler: fn url ->
      fb_redirect_uri = Path.join(url, "/login/callback/facebook")
      put_in_oauth_fb([:redirect_uri], fb_redirect_uri)
      put_in_env(:captain_fact, [:frontend_url], url)
      add_url_to_cors(url)
    end
  )

  weave(
    "cors_allow_all",
    handler: fn value ->
      if value in ~w(yes YES Yes true TRUE True) do
        Logger.warn("Disabling CORS for captain_fact")
        add_url_to_cors("*")
      end

      :ok
    end
  )

  weave("chrome_extension_id", handler: fn value -> add_url_to_cors(value) end)

  # Endpoint
  weave("host", handler: fn v -> put_in_endpoint([:url, :host], v) end)

  weave(
    "secret_key_base",
    handler: fn v ->
      put_in_endpoint([:secret_key_base], v)

      put_in_env(
        :captain_fact,
        [
          CaptainFact.Authenticator.GuardianImpl,
          :secret_key
        ],
        v
      )
    end
  )

  # Mailer
  weave("mailgun_domain", handler: fn v -> put_in_mailer([:domain], v) end)
  weave("mailgun_api_key", handler: fn v -> put_in_mailer([:api_key], v) end)

  # Facebook OAUTH
  weave("facebook_app_id", handler: fn v -> put_in_oauth_fb([:client_id], v) end)
  weave("facebook_app_secret", handler: fn v -> put_in_oauth_fb([:client_secret], v) end)

  # Youtube API key
  weave("youtube_api_key", handler: {:captain_fact, :youtube_api_key})

  # Erlang cookie
  weave(
    "erlang_cookie",
    handler: fn v ->
      Logger.info("Loaded erlang cookie from secrets")
      if Node.alive?(), do: Node.set_cookie(String.to_atom(v))
      :ok
    end
  )

  # ----- Configuration utils -----

  defp put_in_env(app, [head | keys], value) do
    base = Application.get_env(app, head, [])

    modified =
      case keys do
        [] -> value
        _ -> put_in(base, keys, value)
      end

    Application.put_env(app, head, modified)
  end

  defp put_in_endpoint(keys, value),
    do: put_in_env(:captain_fact, [CaptainFactWeb.Endpoint] ++ keys, value)

  defp put_in_mailer(keys, value),
    do: put_in_env(:captain_fact, [CaptainFactMailer] ++ keys, value)

  defp put_in_oauth_fb(keys, value),
    do: put_in_env(:captain_fact, [:oauth, :facebook] ++ keys, value)

  # Avoid duplicates in CORS and ignore configuration if wildcarded.
  defp add_url_to_cors(url) do
    existing_cors = Application.get_env(:captain_fact, :cors_origins)
    new_cors = generate_cors(existing_cors, url)

    # Update CORS for REST endpoint
    Application.put_env(:captain_fact, :cors_origins, new_cors)

    # Update CORS for websockets
    if new_cors == "*" do
      put_in_env(:captain_fact, [CaptainFactWeb.Endpoint, :check_origin], false)
    else
      put_in_env(:captain_fact, [CaptainFactWeb.Endpoint, :check_origin], [new_cors])
    end
  end

  defp generate_cors(existing_cors, new_url) when existing_cors == "*" or new_url == "*",
    do: "*"

  defp generate_cors(existing_cors, new_url) when is_binary(existing_cors),
    do: [existing_cors, new_url]

  defp generate_cors(existing_cors, new_url) when is_list(existing_cors),
    do: existing_cors ++ [new_url]
end
