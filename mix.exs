defmodule NostrElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :nostr_elixir,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/your-username/nostr_elixir",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.32.0"},
      {:jason, "~> 1.4"},
      {:toml, "~> 0.7"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    A complete Elixir wrapper for the nostr Rust library, built with Rustler for high performance.
    Provides key management, text parsing, NIP-19 encoding/decoding, event creation, and filter management.
    """
  end

  defp package do
    [
      name: "nostr_elixir",
      files: ~w(lib native mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/your-username/nostr_elixir",
        "nostr Rust Library" => "https://github.com/rust-nostr/nostr"
      }
    ]
  end
end
