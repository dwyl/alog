defmodule Alog.MixProject do
  use Mix.Project

  def project do
    [
      app: :alog,
      version: "0.5.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger]] ++ mod(Mix.env())
  end

  defp mod(:test), do: [mod: {Alog.TestApp.Application, []}]
  defp mod(_), do: []

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 2.2.10"},
      {:postgrex, ">= 0.0.0"}
    ]
  end
end
