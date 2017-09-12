defmodule Kora.Group do
	def subscribe(group) do
		Registry.register(Kora.Group, group, self())
	end

	def broadcast(group, msg) do
		group
		|> members
		|> Enum.each(&send(&1, {:broadcast, group, msg}))
	end

	def members(group) do
		Kora.Group
		|> Registry.lookup(group)
		|> Enum.map(fn {key, _value} -> key end)
	end
end