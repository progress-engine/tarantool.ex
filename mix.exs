defmodule Tarantool.Mixfile do
  use Mix.Project

  def project do
    [app: :tarantool,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description,
     package: package,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
    {:message_pack, "~> 0.2.0"},
    {:connection, "~> 1.0"}]
  end

  defp description do
    """
    Tarantool client for Elixir language
    """
  end

  defp package do
    [# These are the default files included in the package
     files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["Alexey Poimtsev"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/progress-engine/tarantool.ex"}]
  end

end
