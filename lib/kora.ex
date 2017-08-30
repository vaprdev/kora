defmodule Kora do
	alias Kora.Mutation
	alias Kora.Store
	alias Kora.Query
	alias Kora.Interceptor
	alias Kora.Dynamic
	alias Kora.Config
	require IEx

	@master "kora-master"

	def init do
		[ Config.read() | Config.writes() ]
		|> MapSet.new
		|> Enum.each(fn {store, arg} -> store.init(arg) end)
	end

	def scrap do
		1..100
		|> Task.async_stream(fn val ->
			merge([val], 1)
		end)
		|> Enum.to_list
	end

	def delete(path, user \\ @master) do
		Mutation.new
		|> Mutation.delete(path)
		|> mutation(user)
	end

	def merge(path, value, user \\ @master) do
		Mutation.new
		|> Mutation.merge(path, value)
		|> mutation(user)
	end

	def mutation(mut, user \\ @master) do
		interceptors = Config.interceptors()
		with _ <- 1,
			nil <- Interceptor.validate_write(interceptors, mut, user),
			prepared = %{merge: merge, delete: delete} <- Interceptor.prepare(interceptors, mut, user)
		do
			Kora.Watch.broadcast_mutation(prepared)

			Config.writes()
			|> Task.async_stream(&Store.write(&1, prepared))
			|> Stream.run

			Interceptor.commit(interceptors, prepared, user)
			{:ok, prepared}
		end
	end

	def query(query, user \\ @master) do
		case Interceptor.validate_read(Config.interceptors(), query, user) do
			nil ->
				query
				|> Query.flatten
				|> Task.async_stream(fn {path, opts} ->
					{ path, opts, query_path(path, opts, user, true) } 
				end)
				|> Stream.map(fn {:ok, value} -> value end)
				|> Enum.reduce(Mutation.new, fn {path, opts, data}, collect ->
					collect
					|> Mutation.merge(path, data)
					|> delete(path, opts)
				end)
			result -> result
		end
	end

	defp delete(mutation, path, opts) do
		cond do
			opts === %{} ->
				mutation
				|> Mutation.delete(path)
			true -> mutation
		end
	end

	def query_path(path, opts \\ %{}, user \\ @master) do
		interceptors = Config.interceptors()
		case Interceptor.validate_read(interceptors, path, opts, user) do
			nil ->
				Interceptor.resolve(interceptors, path, user, opts) || query_path(path, opts, user, true)
			result -> result
		end
	end

	defp query_path(path, opts, user, true) do
		case Interceptor.resolve(Config.interceptors(), path, user, opts) do
			nil -> 
				Config.read()
				|> Store.query_path(path, opts)
			result -> result
		end
	end

	def index(mut, name, path), do: index(mut, name, path, path)

	@spec index(map, list(String.t), list(String.t)) :: map
	def index(mut, name, path, prefix) do
		next =
			case Dynamic.get(mut.merge, path) do
				result when is_binary(result) -> result
				result -> inspect(result)
			end
		mut =
			case query_path(path) do
				nil -> mut
				old -> Mutation.delete(mut, name ++ [inspect(old)] ++ prefix)
			end
		mut
		|> Mutation.merge(name ++ [next] ++ prefix, :os.system_time(:millisecond))
	end

end
