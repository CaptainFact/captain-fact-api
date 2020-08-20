defmodule CF.Umbrella.Mixfile do
  use Mix.Project

  def project do
    [
      version: "1.2.0",
      apps_path: "apps",
      deps_path: "deps",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      releases: [
        full_app: [
          applications: [
            cf_reverse_proxy: :permanent,
            cf_jobs: :permanent
          ]
        ]
      ]
    ]
  end

  defp deps do
    [
      # ---- Release ----
      {:distillery, "~> 2.1", runtime: false},

      # ---- Test and Dev
      {:excoveralls, "~> 0.12.1", only: :test},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "ecto.seed"],
      "ecto.seed": ["run apps/db/priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
