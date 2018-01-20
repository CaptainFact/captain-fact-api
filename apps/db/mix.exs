defmodule DB.Mixfile do
  use Mix.Project

  def project do
    [
      app: :db,
      version: "0.7.7",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../_deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
    ]
  end

  def application do
    [
      mod: {DB.Application, []},
      extra_applications: [:logger, :ecto, :postgrex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:ecto, "~> 2.2.8"},
      {:postgrex, "~> 0.13.3"},
      {:arc, "~> 0.8.0"},
      {:arc_ecto, "~> 0.7.0"},
      {:weave, "~> 3.0"},
      {:slugger, "~> 0.2"},
      {:comeonin, "~> 3.0"},
      {:burnex, "~> 1.0"},
      {:hashids, "~> 2.0"},
      {:faker, "~> 0.7"}, # TODO Only test
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
