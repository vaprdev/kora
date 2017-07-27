defmodule Kora.Interceptor do
	alias Kora.Mutation

	def resolve(interceptors, path, user, opts) do
		interceptors
		|> Stream.map(&(&1.resolve_query(path, user, opts)))
		|> Stream.filter(&(&1 !== nil))
		|> Enum.at(0)
	end

	def prepare(interceptors, mutation, user) do
		mutation
		|> Mutation.layers
		|> Enum.reduce(mutation, &prepare(interceptors, &2, user, &1))
	end

	defp prepare(interceptors, mutation, user, {path, data}) do
		Enum.reduce(interceptors, mutation, fn interceptor, collect ->
			case interceptor.intercept_write(path, user, data, collect) do
				# {:prepare, result, next} ->
				# 	prepare(next, interceptors, user)
				# 	|> Mutation.combine(result)
				# :ok -> collect
				{:ok, result } -> result
			end
		end)
	end

	def validate_read(_interceptors, _path, opts, "kora-master"), do: nil

	def validate_read(interceptors, path, opts, user) do
		interceptors
		|> Stream.map(fn mod ->
			
		end)
	end

	def validate_write(_interceptors, _mut, "kora-master"), do: nil

	def validate_write(interceptors, mutation, user) do
		interceptors
		|> trigger_interceptors(mutation, :validate_write, user)
	end

	def commit(interceptors, mutation, user) do
		interceptors
		|> trigger_interceptors(mutation, :intercept_commit, user)
	end

	def deliver(interceptors, mutation, user) do
		interceptors
		|> trigger_interceptors(mutation, :intercept_delivery, user)
	end

	defp trigger_interceptors(interceptors, mutation, function, user) do
		mutation
		|> Mutation.layers
		|> Stream.flat_map(&trigger_interceptors(mutation, interceptors, function, user, &1))
		|> Stream.filter(&(&1 !== :ok))
		|> Enum.at(0)
	end

	defp trigger_interceptors(mutation, interceptors, function, user, {path, data}) do
		interceptors
		|> Stream.map(&apply(&1, function, [path, user, data, mutation]))
	end

	defmacro __using__(_opts) do
		quote do
			@before_compile Kora.Interceptor
		end
	end

	defmacro __before_compile__(_env) do
		quote do
			def intercept_write(_, _, _, mutation) do
				{:ok, mutation}
			end

			def intercept_delivery(_, _, _, _) do
				:ok
			end

			def intercept_commit(_, _, _, _) do
				:ok
			end

			def resolve_query(_path, _user, _layer) do
				nil
			end

			def validate_write(_path, _user, _layer, _mutation) do
				:ok
			end

			def validate_read(_path, _user, _opts) do
				:ok
			end
		end
	end

end
