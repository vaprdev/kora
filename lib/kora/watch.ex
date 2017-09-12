defmodule Kora.Watch do
	alias Kora.Mutation
	def watch(path) do
		Kora.Groups.subscribe({:mutation, path})
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
