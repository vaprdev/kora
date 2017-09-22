defmodule Kora.Command.Watch do
	use Kora.Command

	def handle_command({"kora.subscribe", _, _}, {_, pid}, state) do
		Kora.Watch.watch([], pid)
		{:reply, true, state}
	end

	def handle_info({:broadcast, {:mutation, _}, mut}, _source, state) do
		{"kora.mutation", mut, state}
	end
end