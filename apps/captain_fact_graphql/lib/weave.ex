defmodule CaptainFactGraphql.Weave do
  @moduledoc """
  Provides runtime configuration using env + secret files
  """
  use Weave
  require Logger

  # ----- Actual configuration -----

  if Mix.env == :prod do
    weave "basic_auth_password", required: true,
      handler: fn v -> put_in_env(:captain_fact_graphql, [:basic_auth, :password], v) end
  else
    weave "basic_auth_password",
      handler: fn v -> put_in_env(:captain_fact_graphql, [:basic_auth, :password], v) end
  end

  # Endpoint
  weave "host", handler: fn v -> put_in_endpoint([:url, :host], v) end
  weave "secret_key_base", handler: fn v -> put_in_endpoint([:secret_key_base], v) end

  # No warnings for unknown secrets
  weave "erlang_cookie", handler: fn _ -> [] end
  weave "youtube_api_key", handler: fn _ -> [] end

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
    do: put_in_env(:captain_fact_graphql, [CaptainFactGraphqlWeb.Endpoint] ++ keys, value)
end