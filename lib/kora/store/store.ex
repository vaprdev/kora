defmodule Kora.Store do
	# @callback delete(config, layers)
	# @callback merge(config, layers)
	# @callback query_path(config, path)

	def write({module, config}, mutation) do
		deletes =
			mutation.delete
			|> Dynamic.flatten
			|> Enum.map(fn {key, _value} -> key end)
		merges =
			mutation.merge
			|> Dynamic.flatten
			|> Enum.map(fn {key, value} -> {key, encode(value)} end)
		module.delete(config, deletes)
		module.merge(config, merges)
	end

	def query_path({module, config}, path, opts \\ %{}) do
		opts = Map.merge(%{
			limit: 0,
		}, opts)
		config
		|> module.query_path(path, opts)
		|> inflate(path, opts)
	end

	def inflate(stream, path, opts) do
		count = Enum.count(path)
		stream
		|> Stream.chunk_by(fn {path, _value} -> Enum.at(path, count) end)
		|> Stream.take(
			case opts.limit do
				0 -> 10_000
				_ -> opts.limit
			end
		)
		|> Stream.flat_map(fn x -> x end)
		|> Enum.reduce(%{}, fn {path, value}, collect -> Dynamic.put(collect, path, decode(value)) end)
		|> Dynamic.get(path)
	end

	def encode(input), do: Poison.encode!(input)
	def decode(input), do: Poison.decode!(input)

end
