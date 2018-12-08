defmodule CF.Graphql.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cf_graphql,
      version: "0.9.3",
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
      {:phoenix, "~> 1.3.0"},
      {:plug, "~> 1.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:cowboy, "~> 1.0"},
      {:corsica, "~> 1.0"},
      {:absinthe_ecto, "~> 0.1.3"},
      {:absinthe_plug, "~> 1.4.1"},
      {:basic_auth, "~> 2.2.2"},
      {:kaur, "~> 1.1"},
      {:poison, "~> 3.1"},

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
