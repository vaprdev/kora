defmodule Kora.Application do
	use Application

	def start(_type, _args) do
		import Supervisor.Spec, warn: false
        # Init all stores

		children = [
			supervisor(Registry, [:duplicate, Kora.Watch]),
		]
		opts = [strategy: :one_for_one, name: Kora.Supervisor]
		Supervisor.start_link(children, opts)
	end
end
