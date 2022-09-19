defmodule DepFromHexpm.MixProject do
  use Mix.Project

  def project do
    [
      app: :dep_from_hexpm,
      version: "0.3.0",
      elixir: "~> 1.5",
      deps: deps(),
      package: package(),
      name: "dep_from_hexpm",
      description: "Remember to keep good posture and stay hydrated!"
    ]
  end

  def application do
    [
      mod: {DepFromHexpm, []}
    ]
  end

  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package do
    [
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/thth/dep_from_hexpm"}
    ]
  end
end
