defmodule Kora do
	alias Kora.Mutation
	alias Kora.Store
	alias Kora.Store.Level

	@master "kora-master"

	def read_store do
		{Kora.Store.Level, {}}
	end

	def write_stores do
		[
			{Kora.Store.Level, {}}
		]
	end

	def interceptors do
		[]
	end

	def scrap do
		1..100
		|> Task.async_stream(fn _ ->
			query_path(["hello"])
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
		write_stores()
		|> Task.async_stream(fn store ->
			Store.write(store, mut)
		end)
		|> Stream.run
	end

	def query_path(path, opts \\ %{}, user \\ @master) do
		read_store()
		|> Store.query_path(path, opts)
	end


end
