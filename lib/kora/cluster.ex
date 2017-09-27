defmodule Kora.Group do
	def subscribe(group), do: subscribe(group, self())
	def subscribe(group, pid) do
		Registry.register(__MODULE__, group, pid)
	end

	def broadcast(group, msg) do
		group
		|> members
		|> Enum.each(&send(&1, {:broadcast, group, msg}))
	end

	def members(group) do
		__MODULE__
		|> Registry.lookup(group)
		|> Enum.map(fn {key, _value} -> key end)
	end
end