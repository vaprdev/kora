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
		
	end
end
