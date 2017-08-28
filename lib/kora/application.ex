defmodule Kora.Application do
	use Application

	def start(_type, _args) do
		import Supervisor.Spec, warn: false
        # Init all stores

		children = [
			supervisor(Registry, [:duplicate, Kora.Watch]),
			worker(Kora.Receiver, []),
		]
		opts = [strategy: :one_for_one, name: Kora.Supervisor]
		Supervisor.start_link(children, opts)
	end

	defp cluster do
		mod = Kora.Config.discovery()
		mod.discover()
		mod.register(Kora.Cluster.myself())
	end
end
