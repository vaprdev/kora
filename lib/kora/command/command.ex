defmodule Kora.Command do

	def handle(action, body, version, source, state) do
		{response, result, data} =
			Kora.commands()
			|> Stream.map(&(&1.handle_command({action, body, version}, source, state)))
			|> Stream.filter(&(&1 !== nil))
			|> Stream.take(1)
			|> Enum.at(0) || {:error, :invalid_command, state}
		{
			%{
				action: response,
				body: result,
				version: 1,
			},
			data,
		}
	end

	defmacro __using__(_opts) do
		quote do
			@before_compile Kora.Command
		end
	end

	defmacro __before_compile__(_env) do
		quote do
			def handle_command({_action, _body, _version}, _from, state) do
				nil
			end
		end
	end

end
