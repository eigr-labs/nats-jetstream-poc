defmodule ActorNatsPoc.MixProject do
  use Mix.Project

  def project do
    [
      app: :actor_nats_poc,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ActorNatsPoc.Application, []}
    ]
  end

  defp deps do
    [
      {:broadway, "~> 1.1"},
      {:gnat, "~> 1.8"},
      {:jetstream, "~> 0.0.9"}
    ]
  end
end
