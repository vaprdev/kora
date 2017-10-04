defmodule Kora.Query do
	alias Kora.Dynamic

	def layers(query) do
		query
		|> Dynamic.layers
	end

	def flatten(query, path \\ []) do
		query
		|> Enum.flat_map(fn {key, value} ->
			full = [key | path]
			if path?(value), do: [{Enum.reverse(full), value}], else: flatten(value, full)
		end)
	end

	defp path?(input) do
		input
		|> Map.values
		|> Enum.all?(&(!is_map(&1)))
	end

end
