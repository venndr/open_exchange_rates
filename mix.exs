defmodule OpenExchangeRates.Mixfile do
  use Mix.Project

  def project do
    [
      app: :open_exchange_rates,
      description: "A library that can convert currencies and uses automatic updating of the currrency rates using openexchangerates.org",
      package: package(),
      version: "0.3.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      docs: [extras: ["README.md", "CHANGELOG.md"]],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:decimal, "~> 2.1.1"},
      {:jason, "~> 1.4"},
      {:exvcr, "~> 0.11", only: [:dev, :test]},
      {:credo, "~> 1.4", only: [:dev, :test]},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.22", only: [:dev, :test]},
      {:excoveralls, "~> 0.13", only: :test},
      {:currency_formatter, github: "venndr/currency_formatter", ref: "2f8f0f9e8d73c958780c872cc1e03f1c78a88a88"}
    ]
  end

  defp package do
    [
      maintainers: ["Gerard de Brieder"],
      licenses: ["MIT"],
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*", "CHANGELOG*"],
      links: %{
        "GitHub" => "https://github.com/smeevil/open_exchange_rates",
        "Docs"   => "https://smeevil.github.com/open_exchange_rates",
        "Changelog"   => "https://smeevil.github.com/open_exchange_rates/changelog.html",
      }
    ]
  end
end
