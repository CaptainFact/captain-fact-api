defmodule CaptainFact.ReleaseTasks do
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto
  ]

  @myapps [:captain_fact]

  @repos [CaptainFact.Repo]

  def migrate do
    IO.puts "Loading captainfact for migrations.."
    init()
    Enum.each(@myapps, &run_migrations_for/1)
    IO.puts "Success!"
    :init.stop()
  end

  def seed do
    IO.puts "Loading captainfact for seeding.."
    init()

    # Run the seed script if it exists
    seed_script = Path.join([priv_dir(:captain_fact), "repo", "seeds.exs"])
    if File.exists?(seed_script) do
      IO.puts "Running seed script.."
      Code.eval_file(seed_script)
    end

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  def seed_politicians_from_github() do
    init()
    Application.ensure_all_started(:httpoison)
    seed_script = Path.join([priv_dir(:captain_fact), "repo", "seed_politicians.exs"])
    [{module, _}] = Code.load_file(seed_script)

    url = "https://raw.githubusercontent.com/CaptainFact/captain-fact-data/master/Wikidata/data/politicians_born_after_1945_having_a_picture.csv"
    filename = "politicians.csv"
    %HTTPoison.Response{body: csv_content} = HTTPoison.get!(url)
    File.write!(filename, csv_content)
    apply(module, :seed, [filename])
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp init do
    # Load the code, but don't start it
    :ok = Application.load(:captain_fact)

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos.."
    Enum.each(@repos, &(&1.start_link(pool_size: 1)))
  end

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Ecto.Migrator.run(CaptainFact.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
end