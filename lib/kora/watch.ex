defmodule Kora.Watch do
	alias Kora.Mutation

	def watch(path), do: watch(path, self())
	def watch(path, pid) do
		path
		|> group
		|> Radar.join(pid)
	end

	def broadcast_mutation(mutation) do
		mutation
		|> Mutation.layers
		|> Enum.each(fn {path, value} ->
			inflated = Mutation.inflate(path, value)
			path
			|> group
			|> Radar.broadcast({:mutation, inflated})
		end)
	end

	defp group(path) do
		{:mutation, path}
	end
end
