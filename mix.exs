defmodule ATECC508A.MixProject do
  use Mix.Project

  def project do
    [
      app: :atecc508a,
      version: "0.1.3",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        ignore_warnings: "dialyzer.ignore-warnings"
      ],
      docs: [main: "readme", extras: ["README.md"]],
      description: description(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
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
      links: %{"GitHub" => "https://github.com/nerves-hub/atecc508a"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:x509, "~> 0.5.1 or ~> 0.6"},
      {:circuits_i2c, "~> 0.2"},
      {:ex_doc, "~> 0.11", only: :dev, runtime: false},
      {:dialyxir, "1.0.0-rc.4", only: :dev, runtime: false},
      {:mox, "~> 0.4", only: :test}
    ]
  end
end
