defmodule Kora do
	alias Kora.Mutation
	alias Kora.Store

	@master "kora-master"

	def init, do: config().init()
	def read_store, do: config().read_store()
	def write_stores, do: config().write_stores()
	def interceptors, do: config().interceptors()
	def commands, do: [Kora.Command.Mutation, Kora.Command.Ping | config().commands()]
	def config(), do: Application.get_env(:kora, :config)

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
		interceptors = Kora.interceptors()
		case Kora.Interceptor.validate(interceptors, mut, user) do
			nil ->
				prepared = Kora.Interceptor.prepare(interceptors, mut, user)

				write_stores()
				|> Task.async_stream(&Store.write(&1, prepared))
				|> Stream.run

				{:ok, prepared}

			result -> result
		end
	end

	def query_path(path, opts \\ %{}, _user \\ @master) do
		read_store()
		|> Store.query_path(path, opts)
	end


end
