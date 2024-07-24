defmodule CF.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cf,
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
      mod: {CF.Application, []},
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
      {:phoenix, "~> 1.5.14", override: true},
      {:phoenix_html, "~> 2.14.3"},
      {:gettext, "~> 0.13.1"},
      {:google_api_you_tube, "~> 0.44.0"},
      {:kaur, "~> 1.1"},
      {:bcrypt_elixir, "~> 3.0"},
      {:guardian, "~> 2.0.0"},
      {:guardian_phoenix, "~> 2.0.0"},
      {:guardian_db, "~> 2.1.0"},
      {:floki, "~> 0.34.2"},
      {:html_entities, "~> 0.3"},
      {:httpoison, "~> 2.2"},
      {:poison, "~> 3.1"},
      {:csv, "~> 1.4.4"},
      {:not_qwerty123, "~> 2.2"},
      {:bamboo, "~> 1.7.1"},
      {:hackney, "~> 1.17"},
      {:oauth2, "~> 0.9"},
      {:sweet_xml, "~> 0.6"},
      {:burnex, "~> 3.1"},
      {:yaml_elixir, "~> 2.9.0"},
      {:jason, "~> 1.4"},
      {:openai, "~> 0.6.1"},
      {:sweet_xml, "~> 0.7.4"},

      # ---- Internal ----
      {:db, in_umbrella: true},

      # Dev only
      {:exsync, "~> 0.2", only: :dev},

      # Test only
      {:bypass, "~> 2.1.0", only: :test},
      {:mock, "~> 0.3.1", only: :test}
    ]
  end

  defp aliases do
    []
  end
end
