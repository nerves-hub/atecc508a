defmodule ATECC508A.MixProject do
  use Mix.Project

  @version "1.3.0"
  @source_url "https://github.com/nerves-hub/atecc508a"

  def project do
    [
      app: :atecc508a,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :missing_return, :extra_return],
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      docs: docs(),
      description: description(),
      package: package(),
      source_url: @source_url,
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ATECC508A.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "Elixir interface for the ATECC508A"
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp deps do
    [
      {:x509, "~> 0.5.1 or ~> 0.6"},
      {:circuits_i2c, "~> 1.0 or ~> 0.2 or ~> 2.0"},
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:credo_binary_patterns, "~> 0.2.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
