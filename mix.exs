defmodule Thegm.Mixfile do
  @moduledoc "File that describes the project and its dependencies"
  use Mix.Project

  def project do
    [
      app: :thegm,
      version: "0.0.6",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Thegm, []},
      extra_applications: [:logger, :mailchimp]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:httpoison, "~> 0.13"},
      {:mailchimp, "~> 0.0.6"},
      {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 1.2.14"},
      {:secure_random, "~> 0.5"},
      {:bamboo, "~> 0.8"},
      {:google_maps, "~> 0.8"},
      {:distillery, "~> 1.5", runtime: false},
      {:geo_postgis, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, "~> 1.11"},
      {:mogrify, "~> 0.5.6"},
      {:sweet_xml, "~> 0.6"},
      {:temp, "~> 0.4"},
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:ex_crypto, "~> 0.9.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
