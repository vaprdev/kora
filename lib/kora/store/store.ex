defmodule Kora.Store do
	# @callback delete(config, layers)
	# @callback merge(config, layers)
	# @callback query_path(config, path)
	alias Kora.Dynamic

	def write(store = {module, config}, mutation) do
		deletes =
			mutation.delete
			|> Dynamic.flatten
			|> Enum.map(fn {key, _value} -> key end)
		merges = Dynamic.flatten(mutation.merge)
		module.delete(config, deletes)
		module.merge(config, merges)
	end

	def query_path({module, config}, path, opts \\ %{}) do
		opts = Map.merge(opts, %{
			limit: 0,
		})
		config
		|> module.query_path(path, opts)
		|> inflate(path, opts, module)
	end

	def inflate(stream, path, opts, module) do
		count = Enum.count(path)
		stream
		|> Stream.chunk_by(fn {path, _value} -> Enum.at(path, count) end)
		|> Stream.take(
			case opts.limit do
				0 -> 10000
				_ -> opts.limit
			end
		)
		|> Stream.flat_map(fn x -> x end)
		|> Enum.reduce(%{}, fn {path, value}, collect ->
			Dynamic.put(collect, path, module.decoder(value))
		end)
		|> Dynamic.get(path)
	end

end
