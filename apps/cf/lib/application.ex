defmodule CF.Application do
  use Application

  require Logger

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Other custom supervisors
      supervisor(CF.Sources.Fetcher, []),
      # Misc workers
      worker(CF.Accounts.UsernameGenerator, []),
      # Sweep tokens from db
      worker(Guardian.DB.Token.SweeperServer, []),
    ]

    opts = [strategy: :one_for_one, name: CF.Supervisor]

    goth_credentials = get_goth_worker_credentials()
    if goth_credentials do
      IO.inspect(goth_credentials)
      source = {:refresh_token, goth_credentials, []}
      children = [{Goth, name: CF.Goth, source: source}] ++ children
      Supervisor.start_link(children, opts)
    else
      Supervisor.start_link(children, opts)
    end
  end

  def version() do
    case :application.get_key(:cf, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end

  @doc """
  If Mix is available, returns Mix.env(). If not available (in releases) return :prod
  """
  @deprecated "use Application.get_env(:cf, :env)"
  def env() do
    (Kernel.function_exported?(Mix, :env, 0) && Mix.env()) || :prod
  end

  defp get_goth_worker_credentials() do
    System.fetch_env("GOOGLE_APPLICATION_CREDENTIALS_JSON")
    |> case do
      {:ok, credentials} ->
        case Jason.decode(credentials) do
          {:ok, decoded} ->
            Logger.info("GOOGLE_APPLICATION_CREDENTIALS_JSON found")
            decoded
          {:error, _} ->
            Logger.error("GOOGLE_APPLICATION_CREDENTIALS_JSON is not a valid JSON")
            nil
        end

      _ ->
        Logger.warn("GOOGLE_APPLICATION_CREDENTIALS_JSON not found")
        nil
    end
  end
end
