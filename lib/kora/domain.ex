defmodule Kora.Domain do

	defmacro get(name, path) do
		quote do
			get unquote(name), unquote(path), fn x -> x end
		end
	end

	defmacro get(name, path, callback) do
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
				value = Kora.query_path!(unquote(path))
				unquote(callback).(value)
			end

			def unquote(name)(input) when is_map(input) do
				value = Dynamic.get(input, unquote(direct))
				unquote(callback).(value)
			end
		end
	end

	defmacro extract(a, path, body) do
		quote do
			def unquote(a) do
				result =
					unquote(path)
					|> Kora.query_path!
				unquote(body).(result)
			end
		end
	end

	defmacro map | path do
		quote do
			Dynamic.get(unquote(map), unquote(path))
		end
	end
end

defmodule Kora.Domain.Example do
	import Kora.Domain

	extract patient(arg1, arg2), ["patient"] do

	end
	

end