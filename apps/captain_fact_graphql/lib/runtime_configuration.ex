defmodule CaptainFactGraphql.RuntimeConfiguration do
  @moduledoc """
  Provides runtime configuration using env + secret files
  """
  use Weave
  require Logger


  def setup() do
    secrets_path = if File.exists?("/run/secrets"),
                      do: "/run/secrets",
                      else: Path.join(:code.priv_dir(:captain_fact_graphql), "secrets")

    Application.put_env(:weave, :file_directory, secrets_path)
    Application.put_env(:weave, :only, ~w(basic_auth_password host secret_key_base))
  end

  # ----- Actual configuration -----

  if Application.get_env(:captain_fact_graphql, :env) == :prod do
    weave "basic_auth_password", required: true,
      handler: fn v -> put_in_env(:captain_fact_graphql, [:basic_auth, :password], v) end
  else
    weave "basic_auth_password",
      handler: fn v -> put_in_env(:captain_fact_graphql, [:basic_auth, :password], v) end
  end

  # Endpoint
  weave "host", handler: fn v -> put_in_endpoint([:url, :host], v) end
  weave "secret_key_base", handler: fn v -> put_in_endpoint([:secret_key_base], v) end

  # ----- Configuration utils -----

  defp put_in_env(app, [head | keys], value) do
    base = Application.get_env(app, head, [])
    modified = case keys do
      [] -> value
      _ -> put_in(base, keys, value)
    end
    Application.put_env(app, head, modified)
  end

  defp put_in_endpoint(keys, value),
    do: put_in_env(:captain_fact_graphql, [CaptainFactGraphqlWeb.Endpoint] ++ keys, value)
end