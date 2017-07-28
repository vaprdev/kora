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

	def websocket_handle({:text, content}, state) do
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
		{:reply, {:text, json}, %{
			state |
			data: data,
		}}
	end

	def websocket_handle(_msg, state) do
		{:noreply, state}
	end

	def websocket_info(msg, state) do
		case Kora.Command.trigger_info(msg, {:websocket, self()}, state.data) do
			{:noreply, data} ->
				{:ok, %{
					state |
					data: data
				}}
			{result, data} ->
				json = Poison.encode!(result)
				{:reply, {:text, json}, %{
					state |
					data: data
				}}
		end
	end

end
