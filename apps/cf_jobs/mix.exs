defmodule CF.Jobs.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cf_jobs,
      version: "1.0.4",
      build_path: "../../_build",
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
      mod: {CF.Jobs.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Dependencies
  defp deps do
    [
      {:quantum, "~> 2.3"},
      {:timex, "~> 3.0"},

      # ---- Internal ----
      {:cf, in_umbrella: true},
      {:db, in_umbrella: true}
    ]
  end

  defp aliases do
    []
  end
end
