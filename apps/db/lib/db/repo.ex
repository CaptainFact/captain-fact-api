defmodule DB.Repo do
  use Ecto.Repo, otp_app: :db, adapter: Ecto.Adapters.Postgres
  use Scrivener, page_size: 10

  require Logger

  @doc """
  Ensures the configured database exists on Postgres (runs `CREATE DATABASE` via
  the adapter). Uses `maintenance_database` (default `"postgres"`).

  Safe to call when the DB already exists (`:already_up`).

  Call **before** `start_link`; returns `:ok` or `{:error, reason}`.
  """
  @spec ensure_storage_created() :: :ok | {:error, term()}
  def ensure_storage_created do
    adapter = __adapter__()
    opts = config()

    case adapter.storage_up(opts) do
      :ok ->
        Logger.info("Created Postgres database #{inspect(opts[:database])}")
        :ok

      {:error, :already_up} ->
        :ok

      {:error, reason} ->
        {:error, format_storage_error(reason)}
    end
  end

  defp format_storage_error(reason) when is_binary(reason), do: reason
  defp format_storage_error(reason), do: inspect(reason)
end
