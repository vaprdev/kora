defmodule Kora.Interceptor do
	alias Kora.Mutation
	alias Kora.Query
	require IEx


	def resolve_path(interceptors, path, opts, user) do
		{path, opts}
		|> trigger_layer(interceptors, :resolve_path, [user])
		|> Stream.filter(fn {_, result} -> result !== nil end)
		|> Stream.map(fn {_, result} -> result end)
		|> Enum.at(0)
	end

	def validate_query(interceptors, query, user) do
		query
		|> Query.layers
		|> trigger_interceptors(interceptors, :validate_query, [query, user])
		|> first_error || :ok
	end

	def validate_mutation(interceptors, mutation, user) do
		mutation
		|> Mutation.layers
		|> trigger_interceptors(interceptors, :validate_mutation, [mutation, user])
		|> first_error || :ok
	end

	def before_mutation(interceptors, mutation, user) do
		mutation
		|> Mutation.layers
		|> trigger_interceptors(interceptors, :before_mutation, [mutation, user])
		|> Enum.reduce_while({:ok, mutation}, fn {_, item}, {:ok, collect} ->
			case item do
				:ok -> {:cont, {:ok, collect}}
				{:combine, next} -> {:cont, {:ok, Mutation.combine(collect, next)}}
				result = {:error, _} -> {:halt, result}
			end
		end)
	end

	def after_mutation(interceptors, mutation, user) do
		mutation
		|> Mutation.layers
		|> trigger_interceptors(interceptors, :after_mutation, [mutation, user])
		|> first_error || :ok
	end

	defp trigger_interceptors(layers, interceptors, fun, args) do
		layers
		|> Stream.flat_map(&trigger_layer(&1, interceptors, fun, args))
	end

	defp trigger_layer({path, data}, interceptors, fun, args) do
		interceptors
		|> Stream.map(fn i -> {i, apply(i, fun, [path, data | args])} end)
	end

	defp first_error(stream) do
		stream
		|> Stream.filter(fn input ->
			case input do
				{_, {:error, _}} -> true
				{_, :ok} -> false
			end
		end)
		|> Enum.at(0)
	end

	@type mutation :: %{required(:merge) => map, required(:delete) => map}

	@callback resolve_path(path :: list(String.t), opts :: map, user :: String.t) :: {:ok, any} | {:error, term} | nil
	@callback validate_query(path :: list(String.t), opts :: map, query :: map, user :: String.t) :: :ok | {:error, term}
	@callback validate_mutation(path :: list(String.t), layer :: mutation, mut :: mutation, user :: String.t) :: :ok | {:error, term}
	@callback before_mutation(path :: list(String.t), layer :: mutation, mut :: mutation, user :: String.t) :: :ok | {:error, term} | {:combine, mutation}
	@callback after_mutation(path :: list(String.t), layer :: mutation, mut :: mutation, user :: String.t) :: :ok | {:error, term}

	defmacro __using__(_opts) do
		quote do
			@behaviour Kora.Interceptor
			@before_compile Kora.Interceptor
		end
	end

	defmacro __before_compile__(_env) do
		quote do
			def intercept_delivery(_, _, _, _) do
				:ok
			end

			def resolve_path(_path, _opts, _user) do
				nil
			end

			def validate_query(_path, _opts, _query, _user) do
				:ok
			end

			def validate_mutation(_path, _layer, _mutation, _user) do
				:ok
			end

			def before_mutation(_path, _layer, _mutation, _user) do
				:ok
			end

			def after_mutation(_path, _layer, _mutation, _user) do
				:ok
			end
		end
	end

end
