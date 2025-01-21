defmodule GitHooks.MixProject do
  @moduledoc false

  use Mix.Project

  @source_url "https://github.com/qgadrian/elixir_git_hooks"
  @version "0.8.0"

  def project do
    [
      app: :git_hooks,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      elixirc_options: [
        warnings_as_errors: false
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [plt_add_deps: :app_tree, plt_add_apps: [:mix]]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: "git_hooks",
      description: "Add git hooks to your Elixir projects",
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*", "CODE_OF_CONDUCT*"],
      maintainers: ["Adrián Quintás"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.1", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:inch_ex, ">= 0.0.0", only: :docs},
      {:recase, "~> 0.8.0"}
    ]
  end

  defp aliases do
    [
      coveralls: ["coveralls.html"]
    ]
  end

  defp docs do
    [
      extras: [
        {:"CODE_OF_CONDUCT.md", [title: "Code of Conduct"]},
        {:LICENSE, [title: "License"]},
        "README.md"
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end
end
