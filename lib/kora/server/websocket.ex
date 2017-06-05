defmodule Kora.Websocket do
	@behaviour :cowboy_websocket

	def init(req, _state) do
		{:cowboy_websocket, req, %{
			data: %{},
		}}
	end

	def terminate(_reason, _req, _state) do
		:ok
	end

	def websocket_handle({:text, content}, req, state) do
		%{
			"key" => key,
			"action" => action,
			"body" => body,
			"version" => version,
		} = Poison.decode!(content)

		{result, data} =
			action
			|> Kora.Command.handle(body, version, {:websocket, self()}, state.data)
		result = Map.put(result, :key, key)

		json = Poison.encode!(result)
		{:reply, {:text, json}, req, %{
			state |
			data: data,
		}}
	end

	def websocket_info(msg, req, state) do
		case Kora.Command.handle_info(msg, {:websocket, self()}, state.data) do
			{:noreply, data} ->
				{:ok, req, %{
					state |
					data: data
				}}
			{result, data} ->
				json = Poison.encode!(result)
				{:reply, {:text, json}, req, %{
					state |
					data: data
				}}
		end
	end

end
