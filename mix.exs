defmodule CaptainFact.Mixfile do
  use Mix.Project

  def project do
    [
      app: :captain_fact,
      version: "0.5.0-rc1",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {CaptainFact, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support/factory.ex", "test/support/channel_case.ex"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:corsica, "~> 0.5"},
      {:comeonin, "~> 3.0"},
      {:ueberauth, "0.4.0"},
      {:ueberauth_identity, "~> 0.2"},
      {:ueberauth_facebook, "~> 0.6"},
      {:guardian, "~> 0.10"},
      {:ecto_enum, "~> 1.0"},
      {:arc, "~> 0.8.0"},
      {:arc_ecto, "~> 0.7.0"},
      {:floki, "~> 0.17.0"},
      {:hashids, "~> 2.0"},
      {:html_entities, "~> 0.3"},
      {:httpoison, "~> 0.11.2"},
      {:poison, "~> 2.2.0"},
      {:csv, "~> 1.4.4"},
      {:quantum, ">= 1.9.2"},
      {:not_qwerty123, "~> 2.1"},
      {:bamboo, "~> 1.0.0-rc.1"},
      {:ex_aws, "~> 1.1"},
      {:hackney, "~> 1.6"},
      {:sweet_xml, "~> 0.6"},
      {:weave, "~> 3.0"},
      {:ex_machina, "~> 2.0", only: [:test, :dev]},
      {:faker, "~> 0.7", only: [:test, :dev]},
      {:bypass, "~> 0.8", only: :test},
      {:excoveralls, "~> 0.7", only: :test},
      {:distillery, "~> 1.5", runtime: false}
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
