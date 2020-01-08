defmodule CF.Opengraph.MixProject do
  use Mix.Project

  def project do
    [
      app: :cf_opengraph,
      version: "1.0.4",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applicationss: [:cowboy, :plug],
      extra_applications: [:logger],
      mod: {CF.Opengraph.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.1"},
      {:kaur, "~> 1.1"},
      {:phoenix_html, "~> 2.11.2"},
      {:plug, "~> 1.5.1"},

      # ---- Internal ----
      {:db, in_umbrella: true},

      # ---- Test only ----
      {:sweet_xml, "~> 0.6.5"}
    ]
  end
end
