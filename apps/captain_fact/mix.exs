defmodule CaptainFact.Mixfile do
  use Mix.Project

  def project do
    [
      app: :captain_fact,
      version: "0.8.13",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
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
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.6"},
      {:gettext, "~> 0.13.1"},
      {:google_api_you_tube, "~> 0.1.0"},
      {:kaur, "~> 1.1"},
      {:cowboy, "~> 1.0"},
      {:corsica, "~> 1.0"},
      {:bcrypt_elixir, "~> 1.0"},
      {:guardian, "~> 1.1.0"},
      {:guardian_db, "~> 1.1.0"},
      {:floki, "~> 0.20.2"},
      {:html_entities, "~> 0.3"},
      {:httpoison, "~> 0.11"},
      {:poison, "~> 2.2.0"},
      {:csv, "~> 1.4.4"},
      {:quantum, github: "quantum-elixir/quantum-core"},
      {:timex, "~> 3.0"},
      {:not_qwerty123, "~> 2.2"},
      {:bamboo, github: "thoughtbot/bamboo"},
      {:hackney, "~> 1.6"},
      {:oauth2, "~> 0.9"},
      {:sweet_xml, "~> 0.6"},
      {:weave, "3.1.2"},
      {:burnex, "~> 1.0"},
      {:yaml_elixir, "~> 2.1.0"},

      # ---- Internal ----
      {:db, in_umbrella: true},
      {:cf_utils, in_umbrella: true},

      # Test only
      {:bypass, "~> 0.8", only: :test},
      {:mock, "~> 0.3.1", only: :test}
    ]
  end

  defp aliases do
    []
  end
end
