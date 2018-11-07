defmodule DB.ReleaseTasks do
  @moduledoc """
  Contains release tasks run by `distillery` on startup. You can find the
  entrypoints of these commands in `rel/commands/*.sh`, `rel/hooks/*` and the
  configuration in `rel/config.exs`
  """

  require Logger

  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
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

  def seed do
    init()

    # Run the seed script if it exists
    seed_script = Path.join([priv_dir(:db), "repo", "seeds.exs"])

    if File.exists?(seed_script) do
      Logger.info("Running seed script..")
      Code.eval_file(seed_script)
    else
      Logger.warn("Seed script not found")
    end

    # Signal shutdown
    Logger.info("Success!")
    :init.stop()
  end

  def seed_politicians_from_github() do
    init()
    Application.ensure_all_started(:httpoison)
    seed_script = Path.join([priv_dir(:db), "repo", "seed_politicians.exs"])
    [{module, _}] = Code.load_file(seed_script)

    url =
      "https://raw.githubusercontent.com/CaptainFact/captain-fact-data/master/Wikidata/data/politicians_born_after_1945_having_a_picture.csv"

    filename = "politicians.csv"
    %HTTPoison.Response{body: csv_content} = HTTPoison.get!(url)
    File.write!(filename, csv_content)
    apply(module, :seed, [filename])
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp init do
    # Load the code, but don't start it
    :ok = Application.load(:db)

    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    Logger.info("Dependencies started, loading runtime configuration...")

    # Start the Repo(s) for myapp
    Logger.info("Starting repos..")
    Enum.each(@repos, & &1.start_link(pool_size: 1))
  end

  defp run_migrations_for(app) do
    Logger.info("Running migrations for #{app}")
    Ecto.Migrator.run(DB.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
end
