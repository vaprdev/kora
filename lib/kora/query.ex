defmodule Kora.Query do
	alias Kora.Dynamic

	def new(), do: %{}

	def get(path, opts), do: new() |> get(path, opts)
	def get(query, path, opts) do
		query
		|> Dynamic.put(path, opts)
	end

	def layers(query) do
		query
		|> Dynamic.layers
	end

	def flatten(query, path \\ []) do
		query
		|> Enum.flat_map(fn {key, value} ->
			full = [key | path]
			cond do
				path?(value) ->
					[{Enum.reverse(full), value}]
				true -> flatten(value, full)
			end
		end)
	end

	defp path?(input) do
		input
		|> Map.values
		|> Enum.all?(&(!is_map(&1)))
	end

end
