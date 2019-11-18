defmodule Sonix.MixProject do
  use Mix.Project

  @repo_url "https://github.com/imerkle/sonix"
  @version "0.1.0"

  def project do
    [
      app: :sonix,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        source_url: @repo_url
      ],

      # Hex
      description: "Client for Sonic: Fast, lightweight & schema-less search backend",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @repo_url}
      ]
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
      {:connection, "~> 1.0.4"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
