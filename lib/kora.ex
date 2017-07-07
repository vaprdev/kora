defmodule Kora do
	alias Kora.Mutation
	alias Kora.Store
	alias Kora.Query

	@master "kora-master"

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
		interceptors = Kora.Config.interceptors()
		case Kora.Interceptor.validate(interceptors, mut, user) do
			nil ->
				prepared = Kora.Interceptor.prepare(interceptors, mut, user)

				Kora.Watch.broadcast_mutation(prepared)

				Kora.Config.writes()
				|> Task.async_stream(&Store.write(&1, prepared))
				|> Stream.run

				Kora.Interceptor.commit(interceptors, prepared, user)

				{:ok, prepared}

			result -> result
		end
	end

	def query(query, user \\ @master) do
		query
		|> Query.flatten
		|> Task.async_stream(fn {path, opts} -> { path, opts, query_path(path, opts, user) } end)
		|> Stream.map(fn {:ok, value} -> value end)
		|> Enum.reduce(Mutation.new, fn {path, opts, data}, collect ->
			collect
			|> Mutation.merge(path, data)
			|> delete(path, opts)
		end)
	end

	defp delete(mutation, path, opts) do
		cond do
			opts === %{} ->
				mutation
				|> Mutation.delete(path)
			true -> mutation
		end
	end

	def query_path(path, opts \\ %{}, _user \\ @master) do
		Kora.Config.read()
		|> Store.query_path(path, opts)
	end

	def index(mut, name, path), do: index(mut, name, path, path)
	def index(mut, name, path, prefix), do: index(mut, name, path, prefix, :os.system_time(:millisecond))

	@spec index(map, list(String.t), list(String.t)) :: map
	def index(mut, name, path, prefix, value) do
		next = Kora.Dynamic.get(mut.merge, path) |> inspect
		mut =
			case query_path(path) do
				nil -> mut
				old -> Mutation.delete(mut, name ++ [inspect(old)] ++ prefix)
			end
		mut
		|> Mutation.merge(name ++ [next] ++ prefix, value)
	end

end
