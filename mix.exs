defmodule Kora.Mixfile do
  use Mix.Project

  def project do
	[app: :kora,
	 version: "0.1.0",
	 elixir: "~> 1.5",
	 build_embedded: Mix.env == :prod,
	 start_permanent: Mix.env == :prod,
	 deps: deps()]
  end

  # Configuration for the OTP application
  #
	# Type "mix help compile.app" for more information
	def application do
		# Specify extra applications you'll use from Erlang/Elixir
		[
			extra_applications: [:logger],
			mod: {Kora.Application, []},
		]
	end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
		[
			{:exleveldb, "~> 0.11.0"},
			{:poison, "~> 3.0"},
			{:cowlib, github: "ninenines/cowlib", ref: "master", override: true, manager: :rebar3},
			{:cowboy, github: "ninenines/cowboy", ref: "2.0.0-pre.7", override: true, manager: :rebar3},
			{:postgrex, "~> 0.13.3"},
			{:poolboy, "~> 1.5"},
			{:types, "~> 0.1.6", override: true},
			{:swarm, "~> 3.0"},
			{:libcluster, "~> 2.1"},

			{:dynamic_ex, github: "ironbay/dynamic_ex"},
			{:radar, github: "ironbay/radar"},
		
			{:credo, "~> 0.8", only: [:dev, :test], runtime: false},
			{:dialyxir, "~> 0.5", only: [:dev], runtime: false}

		]
	end
end
