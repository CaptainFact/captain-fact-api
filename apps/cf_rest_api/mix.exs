defmodule CF.RestApi.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cf_rest_api,
      version: "1.1.0",
      build_path: "../../_build",
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      mod: {CF.RestApi.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib"]
  defp elixirc_paths(_), do: ["lib"]

  # Dependencies
  defp deps do
    [
      {:corsica, "~> 2.1"},
      {:cowboy, "~> 2.0"},
      {:gettext, "~> 0.13.1"},
      {:kaur, "~> 1.1"},
      {:phoenix, "~> 1.5.14", override: true},
      {:phoenix_html, "~> 2.14.3"},
      {:phoenix_pubsub, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:plug_cowboy, "~> 2.1"},

      # ---- Internal ----
      {:cf, in_umbrella: true},
      {:db, in_umbrella: true}
    ]
  end

  defp aliases do
    []
  end
end
