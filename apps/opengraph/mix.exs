defmodule Opengraph.MixProject do
  use Mix.Project

  def project do
    [
      app: :opengraph,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applicationss: [:cowboy, :plug],
      extra_applications: [:logger],
      mod: {Opengraph.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.1"},
      {:plug, "~> 1.5.1"},

      # ---- Test only ----
      {:sweet_xml, "~> 0.6.5"}
    ]
  end
end
