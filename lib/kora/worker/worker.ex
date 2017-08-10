defmodule Kora.Worker do

	defmacro __using__(_opts) do
		quote do
			use GenServer
			alias Kora.UUID

			def start_link(key, args), do: GenServer.start_link(__MODULE__, [key, args])

			def init([key, args]) do
				send(self(), :boot)
				{:ok, %{
					key: key,
					args: args,
					data: %{},
				}}
			end

			def handle_info(:boot, state) do
				state.key
				|> path
				|> Kora.merge(%{
					"key" => state.key,
					"args" => state.args,
				})

				state.args
				|> __MODULE__.boot
				|> handle_result(state)
			end

			def handle_info(msg, state), do: msg |> __MODULE__.info(state.data) |> handle_result(state)
			def handle_cast(msg, state), do: msg |> __MODULE__.cast(state.data) |> handle_result(state)
			def handle_call(msg, from, state), do: msg |> __MODULE__.call(from, state.data) |> handle_result(state)

			def path(key), do: ["kora:worker", inspect(__MODULE__), key]

			defp handle_result({:stop, :shutdown, next}, state) do
				state.key
				|> path
				|> Kora.delete
				{:stop, :shutdown, Map.put(state, :data, next)}
			end

			defp handle_result({input, next}, state) do
				{input, Map.put(state, :data, next)}
			end

			defp handle_result({input, msg, next}, state) do
				{input, msg, Map.put(state, :data, next)}
			end

		end
	end

end

defmodule Kora.Worker.Supervisor do
	use Supervisor
	alias Kora.Dynamic

	def start_link(module) do
		Supervisor.start_link(__MODULE__, [module], name: module)
	end

	def init([module]) do
		Task.start_link(fn ->
			:timer.sleep(1_000)
			Kora.Worker.Supervisor.resume(module)
		end)
		Supervisor.init([
			Supervisor.child_spec(module, restart: :transient, start: { module, :start_link, []})
		], strategy: :simple_one_for_one)
	end

	def start_child(module, key, args) do
		Supervisor.start_child(module, [key, args])
	end

	def resume(module) do
		["kora:worker", inspect(module)]
		|> Kora.query_path
		|> IO.inspect
		|> Dynamic.default(%{})
		|> Map.values
		|> Enum.each(fn %{ "args" => args, "key" => key } -> start_child(module, key, args) end)
	end
end