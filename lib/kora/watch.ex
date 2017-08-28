defmodule Kora.Watch do
	alias Kora.Mutation
	def watch(path) do
		sub({:mutation, path})
	end

	def sub(group) do
		Registry.register(__MODULE__, group, 1)
	end

	def members(group) do
		__MODULE__
		|> Registry.lookup(group)
		|> Enum.map(fn {key, _} -> key end)
	end

	def broadcast(group, msg) do
		Kora.Receiver
		|> Kora.Cluster.broadcast({:broadcast_local, self(), group, msg})
		|> Enum.each(fn _ ->
			receive do
				msg -> :done
			end
		end)
	end

	def broadcast_local(group, msg) do
		for pid <- members(group), do: send(pid, {:broadcast, group, msg})
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


defmodule Kora.Receiver do
	use GenServer

	def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

	def init(_) do
		{:ok, {}}
	end

	def handle_cast({:broadcast_local, from, group, msg}, state) do
		Task.start_link(fn ->
			Kora.Watch.broadcast_local(group, msg)
			:partisan_peer_service.forward_message(node(from), from, :ok)
		end)
		{:noreply, state}
	end

end