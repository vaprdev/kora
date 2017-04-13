defmodule Kora.Mutation do
	alias Kora.Dynamic

	def new(merge \\ %{}, delete \\ %{}) do
		%{
			merge: merge || %{},
			delete: delete || %{},
		}
	end

	def merge(input, path, value), do: Dynamic.put(input, [:merge | path], value)
	def delete(input, path), do: Dynamic.put(input, [:delete | path], 1)

	def layers(%{merge: merge, delete: delete}) do
		Dynamic.combine(
			layers(merge, :merge),
			layers(delete, :delete)
		)
		|> Stream.map(fn {path, value} ->
			merge = Map.get(value, :merge, %{})
			delete = Map.get(value, :delete, %{})
			{path, %{
				merge: merge,
				delete: delete,
			}}
		end)
		|> Enum.into(%{})
	end

	def layers(input, type) do
		input
		|> Dynamic.layers
		|> Enum.reduce(%{}, fn {path, value}, collect ->
			Dynamic.put(collect, [path, type], value)
		end)
	end
end
