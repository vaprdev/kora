defmodule Kora.Process do
	defmacro __using__(_opts) do
		quote do
			use GenServer

			def start_link(args) do
				GenServer.start_link(__MODULE__, args)
			end

			def get(args) do
				args
				|> name
				|> Swarm.register_name(Kora.Process.Supervisor, :start_child, [__MODULE__, args])
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
				supervisor(Kora.Process.Supervisor, [__MODULE__], id: __MODULE__)
			end

		end
	end
end