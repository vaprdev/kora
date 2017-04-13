defmodule Kora.Store.Memory do
	alias Kora.Store
	alias Kora.Store.Prefix
	@delimiter "×"
	@table :kora_table
	# use Kora.Store

	def init do
		:ets.new(@table, [
			:ordered_set,
			:public,
			:named_table,
			read_concurrency: true,
			write_concurrency: true,
		])
	end

	def merge(_config, layers) do
		layers
		|> Enum.each(fn {path, value} ->
			joined = Enum.join(path, @delimiter)
			:ets.insert(@table, {joined, value})
		end)
	end

	def delete(_config, layers) do

	end

	def query_path(_config, path, opts) do
		{min, max} = Prefix.range(path, @delimiter, opts)

		iterate_keys(min, max)
		|> Stream.map(&:ets.lookup(@table, &1))
		|> Stream.map(&List.first/1)
		|> Stream.filter(fn item -> item !== nil end)
		|> Stream.map(fn {path, value} -> {String.split(path, @delimiter), value} end)
		|> Store.inflate(path, opts, &(&1))
	end

	def decoder(input), do: input

	defp iterate_keys(min, max) do
		min
		|> Stream.iterate(fn next ->
			cond do
				next === :"$end_of_table" -> :stop
				next >= max -> :stop
				true -> :ets.next(@table, next)
		   end
		end)
		|> Stream.take_while(fn next -> next !== :stop end)
	end

end
