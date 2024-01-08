defmodule DB.Mixfile do
  use Mix.Project

  def project do
    [
      app: :db,
      version: "1.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
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
  defp elixirc_paths(:dev), do: ["lib", "test/support/factory.ex"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # {:arc, github: "Betree/arc", override: true},
      # {:arc_ecto, "~> 0.10.0"},
      {:arc, "~> 0.11.0"},
      {:arc_ecto, "~> 0.11.3"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:ecto_enum, "~> 1.4"},
      {:postgrex, ">= 0.0.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:xml_builder, "~> 2.0", override: true},
      {:slugger, "~> 0.2"},
      {:comeonin, "~> 4.1.1"},
      {:bcrypt_elixir, "~> 1.0"},
      {:burnex, "~> 3.1"},
      {:hashids, "~> 2.0"},
      {:kaur, "~> 1.1"},
      {:mime, "~> 1.2"},
      {:scrivener_ecto, "~> 2.0"},
      {:scout_apm, "~> 1.0.6"},
      {:algoliax, "~> 0.7.1"},

      # Dev only
      {:exsync, "~> 0.2", only: :dev},

      # Test only
      {:ex_machina, "~> 2.0", only: [:dev, :test]},
      {:faker, "~> 0.7", only: [:dev, :test]},
      {:stream_data, "~> 0.5", only: :test}
    ]
  end
end
