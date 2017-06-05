defmodule Kora.Watch do
	alias Kora.Mutation

	def watch(key) do
		Registry.register(__MODULE__, {:mutation, key}, 1)
	end

	def members(key) do
		__MODULE__
		|> Registry.lookup(key)
		|> Enum.map(fn {key, _} -> key end)
	end

	def broadcast(key, data) do
		parent = self()
		[node() | Node.list]
		|> Enum.map(&Node.spawn_link(&1, fn ->
			Kora.Watch.broadcast_local(key, data)
			send(parent, :ok)
		end))
		|> Enum.map(fn pid ->
			receive do
				:ok -> :ok
			end
		end)
	end

	def broadcast_local(key, data) do
		for pid <- members(key), do: send(pid, {:broadcast, key, data})
	end

	def broadcast_mutation(mutation) do
		mutation
		|> Mutation.layers
		|> Enum.each(fn {path, value} ->
			inflated = Mutation.inflate(path, value)
			broadcast({:mutation, path}, inflated)
		end)
	end
end