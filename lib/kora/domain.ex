defmodule Kora.Domain do

	defmacro get(name, path) do
		quote do
			get unquote(name), unquote(path), fn x -> x end
		end
	end

	# defmacro schema(prefix, body) do
	# 	quote do
	# 		@prefix unquote(prefix)
	# 		unquote(body)
	# 	end
	# end

	# defmacro field(name, opts \\ []) do
	# 	direct =
	# 		path
	# 		|> Enum.reverse
	# 		|> Stream.take_while(&is_binary/1)
	# 		|> Enum.reverse
	# 	quote do
	# 		def unquote(name)(key) when is_binary(key) do
	# 			Kora.query_path([@prefix, key, Atom.to_string(unquote(name))])
	# 		end

	# 		def unquote(name)(input) when is_map(input) do
	# 			Kora.Dynamic.get(input, direct)
	# 		end
	# 	end
	# end

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
				value = Kora.Dynamic.get(input, unquote(direct))
				unquote(callback).(value)
			end
		end
	end
end