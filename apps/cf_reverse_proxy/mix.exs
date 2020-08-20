defmodule CF.ReverseProxy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cf_reverse_proxy,
      version: "1.0.0",
      build_path: "../../_build",
      compilers: [:phoenix] ++ Mix.compilers(),
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {CF.ReverseProxy.Application, []},
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
      {:cf_rest_api, in_umbrella: true},
      {:cf_graphql, in_umbrella: true},
      {:cf_atom_feed, in_umbrella: true},
      {:phoenix, "~> 1.3.0"},
      {:cowboy, "~> 1.0"},
      {:corsica, "~> 1.0"}
    ]
  end

  defp aliases do
    []
  end
end
