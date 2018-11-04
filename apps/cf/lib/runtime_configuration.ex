defmodule CF.RuntimeConfiguration do
  @moduledoc """
  Provides runtime configuration using env + secret files
  """
  use Weave
  require Logger

  def setup() do
    secrets_path =
      if File.exists?("/run/secrets"),
        do: "/run/secrets",
        else: Path.join(:code.priv_dir(:cf), "secrets")

    Application.put_env(:weave, :file_directory, secrets_path)

    Application.put_env(:weave, :only, [
      "mailgun_domain",
      "mailgun_api_key",
      "erlang_cookie"
    ])
  end

  # ----- Actual configuration -----

  # Mailer
  weave("mailgun_domain", handler: fn v -> put_in_mailer([:domain], v) end)
  weave("mailgun_api_key", handler: fn v -> put_in_mailer([:api_key], v) end)

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

  defp put_in_mailer(keys, value),
    do: put_in_env(:cf, [CF.Mailer] ++ keys, value)
end
