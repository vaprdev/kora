defmodule Kora.Watch do
	alias Kora.Mutation

	def watch(path), do: watch(path, self())
	def watch(path, pid) do
		Kora.Group.subscribe({:mutation, path}, pid)
	end

	def broadcast_mutation(mutation) do
		mutation
		|> Mutation.layers
		|> Enum.each(fn {path, value} ->
			inflated = Mutation.inflate(path, value)
			Kora.Group.broadcast({:mutation, path}, inflated)
		end)
	end
end
