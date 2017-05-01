defmodule Kora.Dynamic do


	def get(input, [head], fallback, compare) do
		input
		|> Map.get(head)
		|> default(fallback, compare)
	end
	def get(input, [head | tail], fallback, compare) do
		case Map.get(input, head) do
			result when is_map(result) ->
				get(result, tail, fallback, compare)
			_ -> fallback
		end
	end
	@doc ~S"""
	Gets value at path or falls back
	## Examples
		iex> Kora.Dynamic.get(%{a: %{b: 1}}, [:a, :b])
		1
	"""
	def get(input, path) do
		get(input, path, nil, nil)
	end
	@doc ~S"""
	Gets value at path or falls back
	## Examples
		iex> Kora.Dynamic.get(%{a: %{b: 1}}, [:a, :b, :c], :foo)
		:foo
	"""
	def get(input, path, fallback) do
		get(input, path, fallback, nil)
	end

	@doc ~S"""
	Default to fallback if input is nil
	## Examples
		iex> Kora.Dynamic.default(nil, :foo)
		:foo
	"""
	def default(input, fallback), do: default(input, fallback, nil)

	@doc ~S"""
	Default to fallback if input is equal to compare
	## Examples
		iex> Kora.Dynamic.default(:bar, :foo, :bar)
		:foo
	"""
	def default(input, fallback, compare) when input == compare, do: fallback

	@doc ~S"""
	Defaults to input if not equal to compare
	## Examples
		iex> Kora.Dynamic.default(:foo, :bar, :boo)
		:foo
	"""
	def default(input, _compare, _default), do: input

	@doc ~S"""
	Defaults to input if not equal to compare
	## Examples
		iex> Kora.Dynamic.default(:foo, :bar, :boo)
		:foo
	"""
	def put(input, [head], value), do: Map.put(input, head, value)
	def put(input, [head | tail], value) do
		child =
			case Map.get(input, head) do
				result when is_map(result) -> result
				_ -> %{}
			end
		Map.put(input, head, put(child, tail, value))
	end

	def delete(input, [head]), do: Map.delete(input, head)
	def delete(input, [head | tail]) do
		case Map.get(input, head) do
			result when is_map(result) -> Map.put(input, head, delete(result, tail))
			_ -> input
		end
	end

	def combine(left, right), do: Map.merge(left, right, &combine/3)
	defp combine(_key, left = %{}, right = %{}), do: combine(left, right)
	defp combine(_key, _left, right), do: right

	def flatten(input, path \\ []) do
		input
		|> Enum.flat_map(fn {key, value} ->
			full = [key | path]
			cond do
				is_map(value) -> flatten(value, full)
				true -> [{Enum.reverse(full), value}]
			end
		end)
	end

	def layers(input, path \\ []) do
		cond do
			is_map(input) ->
				[
					{Enum.reverse(path), input} |
					Enum.flat_map(input, fn {key, value} ->
						layers(value, [key | path])
					end)
				]
			true -> []
		end
	end

	def primitives(input) do
		input
		|> Stream.filter(fn {_key, value} -> !is_map(value) end)
		|> Enum.into(%{})
	end

	def atom_keys(input), do: for {key, val} <- input, into: %{}, do: {String.to_atom(key), val}
	def string_keys(input), do: for {key, val} <- input, into: %{}, do: {Atom.to_string(key), val}

end
