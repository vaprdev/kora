defmodule Kora.Mutation do
	@typedoc "A map containing a path to be added (merge) and a path to be removed (delete)."
	@type mutation :: %{merge: map, delete: map}

	@typedoc "A key-value pair representing a layer of the mutation. The key 
	is a list of keys representing the path to the current layer. The value is a
	mutation, representing any deeper sub-mutations."
	@type layer :: {list(String.t), mutation}

	@doc ~S"""
	Creates a new mutation with empty delete and merge maps.

	## Example

		iex> Kora.Mutation.new
		%{delete: %{}, merge: %{}}

	"""
	@spec new(map, map) :: mutation
	def new(merge \\ %{}, delete \\ %{}) do
		%{
			merge: merge || %{},
			delete: delete || %{},
		}
	end

	@doc false
	@spec merge(list(String.t), any) :: mutation
	def merge(path, value), do: new() |> merge(path, value)

	@doc ~S"""
	Places the value at the given path in the merge.  
	
	## Example 

		iex> mutation = %{delete: %{}, merge: %{"a" => %{"b" => 1}}}
		iex> Kora.Mutation.merge(mutation, ["a","c"], 2)
		%{delete: %{}, merge: %{"a" => %{"b" => 1, "c" => 2}}}
	
	"""
	@spec merge(mutation, list(String.t), any) :: mutation
	def merge(input, path, value), do: Dynamic.put(input, [:merge | path], value)

	@doc false
	@spec delete(list(String.t)) :: mutation
	def delete(path), do: new() |> delete(path)
	
	@doc ~S"""
	Adds a path to be deleted to the input mutation.
	
	## Example
	
		iex> Kora.Mutation.delete(
		...>	%{
		...>		delete: %{}, 
		...>		merge: %{
		...>			"a" => %{
		...>				"b" => %{
		...>					"c" => true
		...>				}
		...>			}
		...>		}
		...>	},
		...>	["c"]
		...> )
		%{delete: %{"c" => 1}, merge: %{"a" => %{"b" => %{"c" => true}}}}
	"""
	@spec delete(mutation, list(String.t)) :: mutation
	def delete(input, path), do: Dynamic.put(input, [:delete | path], 1)

	@doc ~S"""
	Returns a map of levels for the given mutation. Each level is a key-value 
	pair, where the key is a list of keys representing the current path, and the 
	value is the remaining part of the mutation structure.
	
	## Example 
	
		iex> %{delete: %{}, merge: %{"a" => %{"b" => true}}} |> Kora.Mutation.layers
		%{
			[] => %{
				delete: %{}, 
				merge: %{
					"a" => %{
						"b" => true
					}
				}
			}, 
			["a"] => %{
				delete: %{}, 
				merge: %{
					"b" => true
				}
			}
		}
	"""
	@spec layers(mutation) :: %{required(list(String.t)) => layer}
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

	@doc false
	@spec layers(mutation, :merge | :delete) :: %{required(list(String.t)) => layer}
	def layers(input, type) do
		input
		|> Dynamic.layers
		|> Enum.reduce(%{}, fn {path, value}, collect ->
			Dynamic.put(collect, [path, type], value)
		end)
	end

	@doc ~S"""
	Combines two mutations into one.
	
	## Example

		iex> Kora.Mutation.combine(
		...>	%{delete: %{}, merge: %{"a" => true}}, 
		...>	%{delete: %{}, merge: %{"b" => false}}
		...> )
		%{delete: %{}, merge: %{"a" => true, "b" => false}}
	"""
	@spec combine(mutation, mutation) :: mutation
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

	@doc ~S"""
	Applies the entire mutation to the input map.
	
	## Example 

		iex> Kora.Mutation.apply(
		...> 	%{"b" => false}, 
		...> 	%{delete: %{}, merge: %{"a" => true}}		
		...> )
		%{"a" => true, "b" => false}
	"""
	@spec apply(map, mutation) :: map
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

	@doc ~S"""
	Accepts a list and mutation, and returns a new mutation with the given
	mutation nested at the given path.
	
	## Example
	
		iex> Kora.Mutation.inflate(
		...>	["a", "b"],
		...>	%{
		...>		delete: %{},
		...>		merge: %{
		...>			"a" => 1
		...>		}
		...>	}
		...>)
		%{
			delete: %{
				"a" => %{
					"b" => %{}
				}
			},
			merge: %{
				"a" => %{
					"b" => %{
						"a" => 1
					}
				}
			}
		}
	"""
	@spec inflate(list(String.t), mutation) :: mutation
	def inflate(path, mut) do
		new()
		|> Dynamic.put([:merge | path], mut.merge)
		|> Dynamic.put([:delete | path], mut.delete)
	end

	@doc ~S"""
	Takes two maps and returns a mutation that could be applied to turn the 
	the first map into the second.
	
	## Example
	
		iex> Kora.Mutation.from_diff( 
		...>	%{"a" => 1}, 
		...>	%{"b" => 2}
		...>) 
		%{delete: %{"a" => 1}, merge: %{"b" => 2}}	
	"""
	def from_diff(old, new) do
		old
		|> Dynamic.flatten
		|> Enum.reduce(new(new), fn {path, value}, collect ->
			case Dynamic.get(new, path) do
				^value -> Dynamic.delete(collect, [:merge | path])	
				nil -> delete(collect, path)
				next -> merge(collect, path, next)
			end
		end)
	end
end
