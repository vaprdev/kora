defmodule Kora.Store.Postgres do
	alias Kora.Store.Prefix
	@table :kora_level_table
	@delimiter "."

	def init(name: name) do
		name
		|> Postgrex.query!("""
			CREATE EXTENSION IF NOT EXISTS ltree;
		""", [])

		name
		|> Postgrex.query!("""
			CREATE TABLE IF NOT EXISTS kora (path ltree, value text, PRIMARY KEY(path));
		""", [])
	end

	def query_path([name: name], path, opts) do
		joined = label(path)
		name
		|> Postgrex.query!("""
			SELECT path, value
			FROM kora
			WHERE path <@ $1
		""", [joined])
		|> Map.get(:rows)
		|> Stream.map(fn [path, value] ->
			splits =
				path
				|> String.replace("_", ":")
				|> String.split(@delimiter)
			{splits, value}
		end)
	end

	def merge(config, []), do: nil
	def merge([name: name], layers) do
		{_, statement, params} =
			layers
			|> Enum.reduce({1, [], []}, fn {path, value}, {index, statement, params} ->
				{
					index + 2,
					["($#{index}, $#{index + 1})" | statement],
					[label(path), Poison.encode!(value) | params],
				}
		end)
		name
		|> Postgrex.query!("INSERT INTO kora(path, value) VALUES #{Enum.join(statement, ", ")} ON CONFLICT (path) DO UPDATE SET value = excluded.value", params)
	end

	def delete(config, []), do: nil
	def delete([name: name], paths) do
		statement =
			paths
			|> Enum.with_index
			|> Enum.map(fn {item ,index} -> "path <@ $#{index + 1}" end)
			|> Enum.join("OR")
		name
		|> Postgrex.query!("DELETE FROM kora WHERE #{statement}",
			paths
			|> Enum.map(&label(&1))
		)
	end

	def child_spec(opts) do
		opts = Keyword.merge(opts, [
			types: Kora.Store.Postgres.Types,
			pool_size: 50,
			name: :postgres,
		])
		Postgrex.child_spec(opts)
	end

	defp label(path) do
		path
		|> IO.inspect
		|> Enum.join(@delimiter)
		|> String.replace(":", "_")
	end

end

defmodule Kora.Store.Postgres.LTree do
	@behaviour Postgrex.Extension

	# It can be memory efficient to copy the decoded binary because a
	# reference counted binary that points to a larger binary will be passed
	# to the decode/4 callback. Copying the binary can allow the larger
	# binary to be garbage collected sooner if the copy is going to be kept
	# for a longer period of time. See `:binary.copy/1` for more
	# information.Postgrex.Types.define(MyApp.Types, [{MyApp.LTree, :copy}])

	def init(opts) when opts in [:reference, :copy], do: opts

	# Use this extension when `type` from %Postgrex.TypeInfo{} is "ltree"
	def matching(_opts), do: [type: "ltree"]

	# Use the text format, "ltree" does not have a binary format.
	def format(_opts), do: :text

	# Use quoted expression to encode a string that is the same as
	# postgresql's ltree text format. The quoted expression should contain
	# clauses that match those of a `case` or `fn`. Encoding matches on the
	# value and returns encoded `iodata()`. The first 4 bytes in the
	# `iodata()` must be the byte size of the rest of the encoded data, as a
	# signed 32bit big endian integer.
	def encode(_opts) do
		quote do
			bin when is_binary(bin) ->
			[<<byte_size(bin) :: signed-size(32)>> | bin]
		end
	end

	# Use quoted expression to decode the data to a string. Decoding matches
	# on an encoded binary with the same signed 32bit big endian integer
	# length header.
	def decode(:reference) do
		quote do
			<<len::signed-size(32), bin::binary-size(len)>> ->
			bin
		end
	end
	def decode(:copy) do
		quote do
			<<len::signed-size(32), bin::binary-size(len)>> ->
			:binary.copy(bin)
		end
	end
end

Postgrex.Types.define(Kora.Store.Postgres.Types, [{Kora.Store.Postgres.LTree, :copy}])
