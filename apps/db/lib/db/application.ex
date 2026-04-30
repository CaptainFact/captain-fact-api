defmodule DB.Application do
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    case DB.Repo.ensure_storage_created() do
      :ok ->
        start_repo_and_migrate()

      {:error, reason} ->
        Logger.error(
          "Could not create or reach Postgres database #{inspect(DB.Repo.config()[:database])}: #{reason}"
        )

        {:error, {:could_not_create_database, reason}}
    end
  end

  defp start_repo_and_migrate do
    children = [
      # Starts a worker by calling: DB.Worker.start_link(arg1, arg2, arg3)
      # {DB.Worker, [arg1, arg2, arg3]},
      {DB.Repo, []}
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DB.Supervisor]
    link = Supervisor.start_link(children, opts)
    migrate_db()
    link
  end

  defp migrate_db do
    Logger.info("Running migrations...")
    Ecto.Migrator.run(DB.Repo, migrations_path(), :up, all: true)
    Logger.info("Migrated!")
  end

  defp migrations_path do
    Path.join([:code.priv_dir(:db), "repo", "migrations"])
  end

  def version() do
    case :application.get_key(:db, :vsn) do
      {:ok, version} -> to_string(version)
      _ -> "unknown"
    end
  end
end
