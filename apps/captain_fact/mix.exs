defmodule CaptainFact.Mixfile do
  use Mix.Project

  def project do
    [
      app: :captain_fact,
      version: "0.8.1",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      mod: {CaptainFact.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support/test_utils.ex"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.6"},
      {:gettext, "~> 0.13.1"},
      {:cowboy, "~> 1.0"},
      {:corsica, "~> 1.0"},
      {:comeonin, "~> 3.0"},
      {:ueberauth, "0.4.0"},
      {:ueberauth_identity, "~> 0.2"},
      {:ueberauth_facebook, "~> 0.6"},
      {:guardian, "~> 0.10"},
      {:floki, "~> 0.17.0"},
      {:html_entities, "~> 0.3"},
      {:httpoison, "~> 0.11.2"},
      {:poison, "~> 2.2.0"},
      {:csv, "~> 1.4.4"},
      {:quantum, "~> 2.2.1"},
      {:not_qwerty123, "~> 2.2"},
      {:bamboo, "~> 1.0.0-rc.1"},
      {:hackney, "~> 1.6"},
      {:sweet_xml, "~> 0.6"},
      {:weave, github: "betree/weave", branch: "8-allow-only-keyword-for-selective-configuration"},
      {:burnex, "~> 1.0"},
      {:bypass, "~> 0.8", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:db, in_umbrella: true}
   ]
  end

  defp aliases do
    []
  end
end
