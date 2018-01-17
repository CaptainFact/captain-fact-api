defmodule CaptainFactAPI.Mixfile do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      deps_path: "_deps",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  defp deps do
    [
      {:distillery, "~> 1.5", runtime: false},
    ]
  end
end