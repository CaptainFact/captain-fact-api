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
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.5.1"},
      {:cowboy, "~> 1.1"}
    ]
  end
end
