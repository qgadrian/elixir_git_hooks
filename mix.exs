defmodule GitHooks.MixProject do
  @moduledoc false

  use Mix.Project

  @version "0.4.2"

  def project do
    [
      app: :git_hooks,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
      docs: [
        source_ref: "v#{@version}",
        main: "readme",
        extra_section: "README",
        formatters: ["html", "epub"],
        extras: extras()
      ],
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [plt_add_deps: :transitive, plt_add_apps: [:mix]]
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
      files: ["lib", "priv", "mix.exs", "README*"],
      maintainers: ["Adrián Quintás"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/qgadrian/elixir_git_hooks"}
    ]
  end

  defp description do
    "Add git hooks to your Elixir projects"
  end

  defp deps do
    [
      {:blankable, "~> 1.0.0"},
      {:credo, "~> 1.4.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:inch_ex, ">= 0.0.0", only: :docs},
      {:recase, "~> 0.6.0"}
    ]
  end

  defp aliases do
    [
      compile: ["compile --warnings-as-errors"],
      coveralls: ["coveralls.html"],
      "coveralls.html": ["coveralls.html"]
    ]
  end

  defp extras do
    [
      "README.md"
    ]
  end
end
