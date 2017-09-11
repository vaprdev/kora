defmodule Kora.Group do
	def subscribe(group), do: Swarm.join({__MODULE__, group}, self())

	def broadcast(group, msg), do: Swarm.publish({__MODULE__, group}, {:broadcast, group, msg})

	def members(group), do: Swarm.members({__MODULE__, group})
end