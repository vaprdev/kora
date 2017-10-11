defmodule Kora do
	alias Kora.Mutation
	alias Kora.Store
	alias Kora.Query
	alias Kora.Interceptor
	alias Kora.Dynamic
	alias Kora.Config
	require IEx

	@master "kora-master"

	def init(opts) do
		Config.load(opts)
		[Config.read() | Config.writes()]
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

	def mutation(mut), do: mutation(mut, @master)
	def mutation(mut, @master), do: mutation(mut, @master, :validated)
	def mutation(mut, user) do
		Config.interceptors()
		|> Interceptor.validate_mutation(mut, user)
		|> case do
			:ok -> mutation(mut, user, :validated)
			result -> result
		end
	end
	defp mutation(mut, user, :validated) do
		interceptors = Config.interceptors()
		with _ <- 1,
			{:ok, prepared} <- Interceptor.before_mutation(interceptors, mut, user),
			:ok <- Kora.Watch.broadcast_mutation(prepared),
			_ <-
				Config.writes()
				|> Task.async_stream(&Store.write(&1, prepared))
				|> Stream.run,
			:ok <- Interceptor.after_mutation(interceptors, prepared, user)
		do
			{:ok, prepared}
		end
	end

	def query!(query, user \\ @master) do
		{:ok, result} = Kora.query(query, user)
		result
	end

	def query(query), do: query(query, @master)
	def query(query, @master), do: query(query, @master, :validated)
	def query(query, user) do
		Config.interceptors()
		|> Interceptor.validate_query(query, user)
		|> case do
			:ok -> query(query, user, :validated)
			result -> result
		end
	end
	def query(query, user, :validated) do
		result =
			query
			|> Query.flatten
			|> Task.async_stream(fn {path, opts} ->
				{path, opts, query_path(path, opts, user, :validated)} 
			end, max_concurrency: 100)
			|> Stream.map(fn {:ok, value} -> value end)
			|> Enum.reduce(Mutation.new, fn {path, opts, data}, collect ->
				collect
				|> Mutation.merge(path, data)
				|> case do
					result when opts === %{} -> Mutation.delete(result, path)
					result -> result
				end
			end)
		{:ok, result}
	end

	def query_path!(path, opts \\ %{}, user \\ @master) do
		{:ok, result} = query_path(path, opts, user)
		result
	end

	def query_path(path, opts \\ %{}, user \\ @master) do
		path
		|> Query.get(opts)
		|> query(user)
		|> case do
			{:ok, %{merge: merge}} ->
				{:ok, Dynamic.get(merge, path)}
			result -> result
		end
	end

	defp query_path(path, opts, user, :validated) do
		Config.interceptors()
		|> Interceptor.resolve_path(path, opts, user)
		|> case do
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
			case query_path!(path) do
				nil -> mut
				old -> Mutation.delete(mut, name ++ [inspect(old)] ++ prefix)
			end
		Mutation.merge(name ++ [next] ++ prefix, :os.system_time(:millisecond))
	end
end