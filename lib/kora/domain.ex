defmodule Kora.Domain do
	defmacro get(name, path) do
		count =
			path
			|> Stream.take_while(&is_binary/1)
			|> Enum.count
		direct =
			path
			|> Stream.drop(count + 1)
			|> Enum.to_list

		quote do
			@doc """
			Fetches #{Enum.join(unquote(direct), ".")}
			"""
			def unquote(name)(key) when is_binary(key) do
				var!(key) = key
				Kora.query_path(unquote(path))
			end

			def unquote(name)(input) when is_map(input) do
				Kora.Dynamic.get(input, unquote(direct))
			end
		end
	end
end

defmodule Kora.Domain.Test do
	import Kora.Domain

	get :name, ["user:info", key, "name"]

end