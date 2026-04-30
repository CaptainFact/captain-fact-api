defmodule DB.ReleaseTasks do
  @moduledoc """
  Contains release tasks run on startup. You can find the
  entrypoints of these commands in `rel/commands/*.sh`, `rel/hooks/*` and the
  configuration in `rel/config.exs`
  """

  require Logger

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql,
    :logger
  ]

  @myapps [:db]

  @repos [DB.Repo]

  def migrate do
    init()
    Logger.info("Loading captainfact for migrations..")
    Enum.each(@myapps, &run_migrations_for/1)
    Logger.info("Success!")
    :init.stop()
  end

  @doc """
  Loads dev seed data (Cypress video + admin user) via `DB.Seeds.seed_dev_data/0`.
  For local integration tests against a prod release — not for production containers.
  """
  def seed_dev_data_release do
    init()
    {:ok, _} = Application.ensure_all_started(:bcrypt_elixir)
    DB.Seeds.seed_dev_data()
    :init.stop()
  end

  def seed do
    init()

    # Run the seed script if it exists
    seed_script = Path.join([priv_dir(:db), "repo", "seeds.exs"])

    if File.exists?(seed_script) do
      Logger.info("Running seed script..")
      Code.eval_file(seed_script)
    else
      Logger.warning("Seed script not found")
    end

    # Signal shutdown
    Logger.info("Success!")
    :init.stop()
  end

  def seed_politicians_from_github() do
    init()
    Application.ensure_all_started(:httpoison)
    seed_script = Path.join([priv_dir(:db), "repo", "seed_politicians.exs"])
    [{module, _}] = Code.compile_file(seed_script)

    url =
      "https://raw.githubusercontent.com/CaptainFact/captain-fact-data/master/Wikidata/data/politicians_born_after_1945_having_a_picture.csv"

    filename = "politicians.csv"

    csv_content =
      url
      |> HTTPoison.get!()
      |> Map.fetch!(:body)

    File.write!(filename, csv_content)
    apply(module, :seed, [filename])
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp init do
    # Load the code, but don't start it (eval may already have :db loaded)
    case Application.load(:db) do
      :ok -> :ok
      {:error, {:already_loaded, :db}} -> :ok
      {:error, reason} -> raise "Application.load(:db) failed: #{inspect(reason)}"
    end

    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    Logger.info("Dependencies started, loading runtime configuration...")

    case DB.Repo.ensure_storage_created() do
      :ok ->
        :ok

      {:error, reason} ->
        raise "Could not ensure Postgres database exists: #{reason}"
    end

    # Start the Repo(s) for myapp
    Logger.info("Starting repos..")
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp run_migrations_for(app) do
    Logger.info("Running migrations for #{app}")
    Ecto.Migrator.run(DB.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
end
