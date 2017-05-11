defmodule Kora.Store.Level do
	alias Kora.Store.Prefix
	@table :kora_level_table
	@delimiter "×"

	def init do
		path = Application.get_env(:kora, :level_path)
		{:ok, ref} = Exleveldb.open(path)
		:ets.new(@table, [
			:public,
			:named_table,
			read_concurrency: true,
		])
		:ets.insert(@table, {:ref, ref})
	end

	defp ref do
		{_, value} = @table |> :ets.lookup(:ref) |> List.first
		value
	end

	def query_path(_config, path, opts) do
		{min, max} = Prefix.range(path, @delimiter, opts)
		ref()
		|> Exleveldb.iterator
		|> stream(min, max)
		|> Stream.map(fn {path, value} -> {String.split(path, @delimiter), value} end)
	end

	def merge(_config, layers) do
		ref = ref()
		layers
		|> Enum.each(fn {path, value} ->
			joined = Enum.join(path, @delimiter)
			Exleveldb.put(ref, joined, value)
		end)
	end

	def delete(_config, paths) do
		ref = ref()
		paths
		|> Stream.flat_map(fn path ->
			{min, max} = Kora.Store.Prefix.range(path, @delimiter, %{})
			ref
			|> Exleveldb.iterator([], :keys_only)
			|> stream(min, max)
			|> Enum.to_list
		end)
		|> Enum.each(fn path ->
			Exleveldb.delete(ref, path)
		end)
	end

	defp stream({:ok, iter}, min, max) do
		Stream.resource(
			fn -> {min, iter} end,
			fn {op, iter}->
				case Exleveldb.iterator_move(iter, op) do
					{:ok, path} when path > max -> {:halt, iter}
					{:ok, path, _value} when path > max -> {:halt, iter}
					{:error, :invalid_iterator} -> {:halt, iter}

					{:ok, path} -> {[path], {:next, iter}}
					{:ok, path, value}-> {[{path, value}], {:next, iter}}
				end
			end,
			fn iter -> Exleveldb.iterator_close(iter) end
		)
	end

	def decoder(input), do: input

end
