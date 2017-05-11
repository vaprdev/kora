defmodule Kora.Server do
	def start_link(port) do
		:cowboy.start_http(
			:http,
			100,
			[{:port, port}],
			[{:env, [{:dispatch, config()}]}]
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
end
