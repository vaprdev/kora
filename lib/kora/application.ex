defmodule Kora.Application do
	use Application

	def start(_type, _args) do
		import Supervisor.Spec, warn: false
		Kora.Store.Level.init()
		# Define workers and child supervisors to be supervised
		children = []

		# See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
		# for other strategies and supported options
		opts = [strategy: :one_for_one, name: Clank.Supervisor]
		Supervisor.start_link(children, opts)
	end
end
