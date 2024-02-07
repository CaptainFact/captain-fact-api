defmodule CF.Graphql.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cf_graphql,
      version: "1.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      mod: {CF.Graphql.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.4.18"},
      {:plug, "~> 1.7"},
      {:phoenix_pubsub, "~> 1.0"},
      {:cowboy, "~> 2.0"},
      {:corsica, "~> 2.1"},
      {:absinthe_ecto, "~> 0.1.3"},
      {:absinthe_plug, "~> 1.4.1"},
      {:kaur, "~> 1.1"},
      {:poison, "~> 3.1"},
      {:scout_apm, "~> 1.0.6"},

      # Internal dependencies
      {:db, in_umbrella: true},
      {:cf, in_umbrella: true},

      # Dev only
      {:exsync, "~> 0.2", only: :dev}
    ]
  end

  defp aliases do
    []
  end
end
