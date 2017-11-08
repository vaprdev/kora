defmodule Kora.Application do
	use Application

	def start(_type, _args) do
		import Supervisor.Spec, warn: false
		children = [
			worker(Registry, [[keys: :duplicate, name: Kora.Group]]),
			Kora.Graph.Node.supervisor_spec(),
			Kora.Agent.Example.supervisor_spec(),
			Kora.Worker.Example.supervisor_spec(),
		]
		opts = [strategy: :one_for_one, name: Kora.Supervisor]
		Supervisor.start_link(children, opts)
	end

end
