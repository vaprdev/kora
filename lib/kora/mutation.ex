defmodule Kora.Mutation do
	alias Kora.Dynamic

	@type t :: %{merge: map, delete: map}

	@type layer :: {list(String.t), t}

	@spec new(map, map) :: Mutation.t
	def new(merge \\ %{}, delete \\ %{}) do
		%{
			merge: merge || %{},
			delete: delete || %{},
		}
	end

	@spec merge(list(String.t), any) :: Mutation.t
	def merge(path, value), do: new() |> merge(path, value)

	@spec merge(Mutation.t, list(String.t), any) :: Mutation.t
	def merge(input, path, value), do: Dynamic.put(input, [:merge | path], value)

	@spec delete(list(String.t)) :: Mutation.t
	def delete(path), do: new() |> delete(path)

	@spec delete(t, list(String.t)) :: Mutation.t
	def delete(input, path), do: Dynamic.put(input, [:delete | path], 1)

	@spec layers(Mutation.t) :: %{required(list(String.t)) => Mutation.layer}
	def layers(%{merge: merge, delete: delete}) do
		merge
		|> layers(:merge)
		|> Dynamic.combine(layers(delete, :delete))
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

	@spec layers(Mutation.t, :merge | :delete) :: %{required(list(String.t)) => layer}
	def layers(input, type) do
		input
		|> Dynamic.layers
		|> Enum.reduce(%{}, fn {path, value}, collect ->
			Dynamic.put(collect, [path, type], value)
		end)
	end

	@spec combine(Mutation.t, Mutation.t) :: Mutation.t
	def combine(left, right) do
		%{
			merge:
				left.merge
				|> Kora.Mutation.apply(%{delete: right.delete, merge: %{}})
				|> Kora.Mutation.apply(%{delete: %{}, merge: right.merge}),
			delete: Dynamic.combine(
				left.delete,
				right.delete
			),
		}
	end

	@spec apply(map, Mutation.t) :: map
	def apply(input, mutation) do
		deleted =
			mutation.delete
			|> Dynamic.flatten
			|> Enum.reduce(input, fn {path, _value}, collect ->
				Dynamic.delete(collect, path)
			end)
		mutation.merge
		|> Dynamic.flatten
		|> Enum.reduce(deleted, fn {path, value}, collect ->
			Dynamic.put(collect, path, value)
		end)
	end

	@spec inflate(list(String.t), Mutation.t) :: Mutation.t
	def inflate(path, mut) do
		new()
		|> Dynamic.put([:merge | path], mut.merge)
		|> Dynamic.put([:delete | path], mut.delete)
	end
end
