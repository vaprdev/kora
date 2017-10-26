defmodule Kora.Store.Postgres do
    alias Kora.Store.Prefix
	@delimiter "×"

	def init(name: name) do
		name
		|> Postgrex.query!("""
			CREATE EXTENSION IF NOT EXISTS ltree;
		""", [], pool: DBConnection.Poolboy)

		name
		|> Postgrex.query!("""
			CREATE TABLE IF NOT EXISTS kora (
                path text,
                value text,
                PRIMARY KEY(path)
            );
		""", [], pool: DBConnection.Poolboy)
	end

	def query_path([name: name], path, opts) do
		{min, max} = Prefix.range(path, @delimiter, opts)
		{:ok, result} =
			name
			|> Postgrex.transaction(fn conn ->
				conn
				|> Postgrex.stream("""
					SELECT path, value
					FROM kora
					WHERE path >= $1 AND path < $2 ORDER BY path ASC
				""", [min, max])
				|> Stream.map(&Map.get(&1, :rows))
				|> Stream.flat_map(&(&1))
				|> Stream.map(fn [path, value] ->
					splits = String.split(path, @delimiter)
					{splits, value}
				end)
				|> Enum.to_list
			end, pool: DBConnection.Poolboy)
		result
	end

	def merge(_config, []), do: nil
	def merge([name: name], layers) do
		{_, statement, params} =
			layers
			|> Enum.reduce({1, [], []}, fn {path, value}, {index, statement, params} ->
				{
					index + 2,
					["($#{index}, $#{index + 1})" | statement],
					[Enum.join(path, @delimiter), value | params],
				}
            end)
		{:ok, _} =
			name
			|> Postgrex.transaction(fn conn ->
				Postgrex.query!(conn, "INSERT INTO kora(path, value) VALUES #{Enum.join(statement, ", ")} ON CONFLICT (path) DO UPDATE SET value = excluded.value", params)
			end, pool: DBConnection.Poolboy)
	end

	def delete(_config, []), do: nil
	def delete([name: name], paths) do
		{arguments, statement} =
			paths
            |> Enum.with_index
            |> Stream.map(fn {path, index} ->
                index = index * 2
                {min, max} = Prefix.range(path, @delimiter, %{min: nil, max: nil})
                {[min, max], "(path >= $#{index + 1} AND path < $#{index + 2})"}
            end)
            |> Enum.reduce({[], []}, fn {args, field}, {a, b} -> {args ++ a, [field | b]} end)
        statement = Enum.join(statement, "OR")
		name
		|> Postgrex.transaction(fn conn ->
			conn
			|> Postgrex.query!("DELETE FROM kora WHERE #{statement}", arguments)
		end, pool: DBConnection.Poolboy)
	end

	def child_spec(opts) do
		opts = Keyword.merge([
			pool_size: 50,
			name: :postgres,
			pool: DBConnection.Poolboy,
        ], opts)
		Postgrex.child_spec(opts)
	end

end
