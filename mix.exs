defmodule UeberauthSpotify.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ueberauth_spotify,
      version: "0.2.1",
      name: "Ueberauth Spotify Strategy",
      package: package(),
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/markusherzog/ueberauth_spotify",
      homepage_url: "https://github.com/markusherzog/ueberauth_spotify",
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  def application do
    [applications: [:logger, :oauth2, :ueberauth]]
  end

  defp deps do
    [
      {:ueberauth, "~> 0.10.3"},
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp docs do
    [extras: docs_extras(), main: "extra-readme"]
  end

  defp docs_extras do
    ["README.md"]
  end

  defp description do
    "An Uberauth strategy for Spotify authentication."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE", ".gitignore"],
      maintainers: ["Markus Herzog"],
      licenses: ["MIT"],
      links: %{GitHub: "https://github.com/markusherzog/ueberauth_spotify"}
    ]
  end
end
