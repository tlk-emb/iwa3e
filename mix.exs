defmodule ElixirProfiler.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_profiler,
      version: "0.1.0",
      elixir: "~> 1.9",
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
      {:recon, "~> 2.5"},
      {:plotly_ex, git: "https://github.com/s417-lama/plotly_ex.git"},
      {:observer_cli, "~> 1.5"},
    ]
  end
end
