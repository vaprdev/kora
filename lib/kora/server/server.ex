defmodule Kora.Server do
	def start_link(port) do
		:cowboy.start_clear(
			:http,
			100,
			[{:port, port}],
			%{
				env: %{
					dispatch: config()
				}
			}
		)
	end

	defp config do
		:cowboy_router.compile([
			{
				:_, [
					{"/socket", Kora.Websocket, []}
				]
			}
		])
	end

	def child_spec do
		import Supervisor.Spec
		worker(__MODULE__, [12_000])
	end
end
