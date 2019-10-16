defmodule BatchLoader.MixProject do
  use Mix.Project

  @version "0.1.0-beta.5"

  def project do
    [
      app: :batch_loader,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs_config(),
      source_url: "https://github.com/exAspArk/batch_loader",
      test_coverage: [tool: ExCoveralls]
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
      {:absinthe, "~> 1.4.0 or ~> 1.5.0-beta"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11", only: :test},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp description() do
    "Powerful tool to avoid N+1 DB or HTTP queries"
  end

  defp package do
    [
      maintainers: ["exAspArk"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/exAspArk/batch_loader"}
    ]
  end

  defp docs_config do
    [
      extras: [
        {"README.md", [title: "Overview"]},
        {"CHANGELOG.md", [title: "Changelog"]}
      ],
      main: "readme"
    ]
  end
end
