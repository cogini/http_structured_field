defmodule HttpStructuredField.MixProject do
  use Mix.Project

  @github "https://github.com/cogini/http_structured_field"

  def project do
    [
      app: :http_structured_field,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix, :eex]
        # plt_add_deps: true,
        # flags: ["-Werror_handling", "-Wrace_conditions"],
        # flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs],
        # ignore_warnings: "dialyzer.ignore-warnings"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      # xref: [
      #   exclude: [EEx, :cover]
      # ]
    ]
  end

  def application do
    [
      extra_applications: [:logger] ++ extra_applications(Mix.env()),
    ]
  end

  defp extra_applications(env) when env in [:dev, :test], do: [:eex]
  defp extra_applications(_),     do: []

  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:nimble_parsec, "~> 1.1"}
    ]
  end

  defp description do
    "Mix task to generate Ecto migrations from SQL schema file"
  end

  defp package do
    [
      maintainers: ["Jake Morrison"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @github}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_url: @github,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
