defmodule Kora.Process.Supervisor do
	def start_link(module) do
		Supervisor.start_link(__MODULE__, [module], name: module)
	end

	def init([module]) do
		import Supervisor.Spec
		children = [
			worker(module, [], restart: :transient)
		]
		supervise(children, strategy: :simple_one_for_one)
	end

	def start_child(module, args) do
		{:ok, _} = Supervisor.start_child(module, [args])
	end
end