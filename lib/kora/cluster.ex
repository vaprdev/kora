defmodule Kora.Cluster do
	use GenServer

	def start_link, do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

	def init(_), do: {:ok, {}}

	def handle_cast(all = {:broadcast_local, from, group, msg}, state) do
		Task.start_link(fn ->
			Kora.Groups.broadcast(group, msg)
			cast(node(from), from, :ok)
		end)
		{:noreply, state}
	end

	def members do
		{:ok, result} = :partisan_peer_service.members
		result
	end

	def myself, do: :partisan_peer_service_manager.myself

	def join(address), do: :partisan_peer_service.join(address)

	def broadcast(group, msg) do
		members
		|> Stream.filter(&(&1 !== Node.self))
		|> Enum.map(&cast(&1, __MODULE__, {:broadcast_local, self(), group, msg}))
		|> Enum.each(fn _ ->
			receive do
				msg -> :done
			end
		end)

		Kora.Groups.broadcast(group, msg)
	end

	def cast(node, pid, msg) do
		:partisan_peer_service.forward_message(node, pid, msg)
	end

end

defmodule Kora.Groups do

	def subscribe(group), do: Registry.register(__MODULE__, group, 1)

	def broadcast(group, msg) do
		group
		|> members
		|> Enum.each(&send(&1, {:broadcast, group, msg}))
	end

	def members(group) do
		__MODULE__
		|> Registry.lookup(group)
		|> Enum.map(fn {key, _} -> key end)
	end

end