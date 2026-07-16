defmodule Moov.MixProject do
  use Mix.Project

  @source_url "https://github.com/iamkanishka/moov"
  @version "1.0.0"

  def project do
    [
      app: :moov,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      description: description(),
      name: "Moov",
      source_url: @source_url,
      dialyzer: dialyzer(),
      aliases: aliases()
    ]
  end

  def application do
    extra =
      if Mix.env() == :test do
        [:logger, :crypto, :plug]
      else
        [:logger, :crypto]
      end

    [extra_applications: extra]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    "A complete, production-grade Elixir client for the Moov API."
  end

  defp package do
    [
      name: "moov",
      maintainers: ["Kanishka naik"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url, "Moov API docs" => "https://docs.moov.io/api"},
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp deps do
    [
      {:req, "~> 0.6.1"},
      {:jason, "~> 1.4.4", override: true},
      {:telemetry, "~> 1.3.0", override: true},
      {:finch, "~> 0.19.0", override: true},
      {:mint, "~> 1.7.1", override: true},
      {:castore, "~> 1.0.14", override: true},
      {:hpax, "~> 0.2.0", override: true},
      {:nimble_options, "~> 1.1.1", override: true},
      {:nimble_pool, "~> 1.1.0", override: true},
      {:mime, "~> 2.0.7", override: true},
      {:ex_doc, "~> 0.40.3", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4.4", only: [:dev, :test], runtime: false},
      {:erlex, "~> 0.2", only: [:dev, :test], runtime: false, override: true},
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false},
      {:bunt, "~> 1.0.0", only: [:dev, :test], runtime: false, override: true},
      {:file_system, "~> 1.0.1", only: [:dev, :test], runtime: false, override: true},
      {:plug, "~> 1.17.0", only: :test},
      {:plug_crypto, "~> 2.1.1", only: :test}
    ]
  end

  defp dialyzer do
    [
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      plt_add_apps: [:mix, :ex_unit],
      flags: [:error_handling, :underspecs, :unmatched_returns]
    ]
  end

  defp aliases do
    [quality: ["format --check-formatted", "credo --strict", "dialyzer"]]
  end
end
