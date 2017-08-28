defmodule Kora.Cluster do
	def members do
		{:ok, result} = :partisan_peer_service.members
		result
	end

	def myself, do: :partisan_peer_service_manager.myself

	def join(address), do: :partisan_peer_service.join(address)

	def broadcast(pid, msg) do
		GenServer.cast(pid, msg)

		members
		|> Stream.filter(&(&1 !== Node.self))
		|> Enum.map(&cast(&1, pid, msg))
	end

	def cast(node, pid, msg) do
		:partisan_peer_service.forward_message(node, pid, msg)
	end

end

defmodule Kora.Cluster.Discovery do
	def register(name) do
		
	end

	def discover() do
	end
end