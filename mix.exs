defmodule ChatEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :chat_ex,
      version: "0.1.0",
      elixir: "~> 1.12-dev",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ChatEx, []}
    ]
  end

  defp deps do
    [
      {:websockex, "~> 0.4.2", only: :test},
      {:mock, "~> 0.3.6", only: :test},

      {:cowboy, "~> 2.8"},
      {:plug, "~> 1.11"},
      {:plug_cowboy, "~> 2.4"},
      {:jason, "~> 1.2"},
      {:poison, "~> 4.0"}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
