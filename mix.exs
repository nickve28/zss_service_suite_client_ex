defmodule ZssClient.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [app: :zss_client,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :uuid, :chumak, :msgpax],
     mod: {ZssClient, []}]
  end

  defp deps do
    [
      {:chumak, "~> 1.2.0"},
      {:msgpax, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:credo, "~> 0.3", only: [:dev, :test]}
    ]
  end
end
