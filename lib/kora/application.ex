defmodule Kora.Application do
	use Application

	def start(_type, _args) do
		import Supervisor.Spec, warn: false
		children = [
			worker(Registry, [[keys: :duplicate, name: Kora.Group]]),
			Kora.Store.Postgres.child_spec([
				hostname: "elb-ridehealth-8531.aptible.in",
				database: "ridehealth",
				username: "aptible",
				password: "NIHFS1fSY5kTtH3GU1Y_04EO1Kt6ZGqe",
				ssl: true,
				name: :next,
			]),
		]
		opts = [strategy: :one_for_one, name: Kora.Supervisor]
		Supervisor.start_link(children, opts)
	end

end
