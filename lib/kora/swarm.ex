defmodule Kora.Swarm do
	defmacro __using__(_opts) do
		quote do
			use GenServer

			def start_link(args) do
				GenServer.start_link(__MODULE__, args)
			end

			def get(args) do
				args
				|> name
				|> Swarm.register_name(Kora.Swarm.Supervisor, :start_child, [__MODULE__, args])
				|> case do
					{:ok, pid} -> pid
					{:error, {:already_registered, pid}} -> pid
				end
			end

			def whereis(args) do
				args
				|> name
				|> Swarm.whereis_name
			end

			def name(args) do
				{__MODULE__, args}
			end

			def handle_call({:swarm, :begin_handoff}, _from, state) do
				{:reply, :restart, state}
			end

			def handle_info({:swarm, :die}, state) do
				{:stop, :shutdown, state}
			end

			def supervisor_spec do
				import Supervisor.Spec
				supervisor(Kora.Swarm.Supervisor, [__MODULE__], id: __MODULE__)
			end

		end
	end
end

defmodule Kora.Swarm.Supervisor do
	def start_link(module) do
		Supervisor.start_link(__MODULE__, [module], name: module)
	end

	def init([module]) do
		import Supervisor.Spec
		children = [
			worker(module, [], restart: :temporary)
		]
		supervise(children, strategy: :simple_one_for_one)
	end

	def start_child(module, args) do
		{:ok, _} = Supervisor.start_child(module, [args])
	end
end

defmodule Kora.Swarm.Example do
	use Kora.Swarm

	def init(_args) do
		{:ok, {}}
	end
end