defmodule Kora.Worker do
	use GenServer
	alias Kora.Dynamic

	def start_link(module, state), do: GenServer.start_link(__MODULE__, [module, state])
	def start_link(module, key, args), do: GenServer.start_link(__MODULE__, [module, key, args], name: String.to_atom("#{inspect(module)}-#{key}"))

	def init([module, key, args]) do
		case (path(key, module) ++ ["data"]) |> Kora.query_path do
			nil ->
				args
				|> module.first
				|> handle_result(%{
					module: module,
					key: key,
					args: args,
					data: %{},
				})
			data ->
				data = Dynamic.atom_keys(data)
				args
				|> module.resume(data)
				|> handle_result(%{
					module: module,
					key: key,
					args: args, data: data,
				})
		end
	end

	def handle_info(msg, state), do: msg |> state.module.handle_info(state.data) |> handle_result(state)
	def handle_cast(msg, state), do: msg |> state.module.handle_cast(state.data) |> handle_result(state)
	def handle_call(msg, from, state), do: msg |> state.module.handle_call(from, state.data) |> handle_result(state)

	def path(key, module), do: ["kora:worker", inspect(module), key]

	defp handle_result({:stop, :shutdown, _next}, state) do
		state.key
		|> path(state.module)
		|> Kora.delete
		{:stop, :shutdown, state}
	end

	defp handle_result({input, next}, state) do
		state = save_state(state, next)
		{input, state}
	end

	defp handle_result({input, msg, next}, state) do
		state = save_state(state, next)
		{input, msg, state}
	end

	defp save_state(state = %{data: old}, next) when next !== old do
		state =
			state
			|> Map.put(:data, next)
		state.key
		|> path(state.module)
		|> Kora.merge(%{
			"module" => state.module,
			"key" => state.key,
			"args" => state.args,
			"data" => Dynamic.string_keys(state.data)
		})
		state
	end

	defp save_state(state, _next), do: state

	def get(module, key, args) do
		case Supervisor.start_child(module, [module, key, args]) do
			{:ok, pid} -> pid
			{:error, {:already_started, pid}} -> pid
		end
	end

	def resume(module) do
		["kora:worker", inspect(module)]
		|> Kora.query_path
		|> Dynamic.default(%{})
		|> Map.values
		|> Enum.each(fn %{"args" => args, "key" => key} ->
			Supervisor.start_child(module, [module, key, args])
		end)
	end

end

defmodule Kora.Worker.Supervisor do
	use Supervisor

	def start_link(module) do
		Supervisor.start_link(__MODULE__, [], name: module)
	end

	def init(_) do
		Supervisor.init([
			Supervisor.child_spec(Kora.Worker, restart: :transient, start: { Kora.Worker, :start_link, []})
		], strategy: :simple_one_for_one)
	end
end