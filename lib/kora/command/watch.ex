defmodule Kora.Command.Watch do
	use Kora.Command

	def handle_command({"kora.subscribe", _, _}, from, state) do
		Kora.watch([])
		{:reply, true, Map.put(state, :watcher, self())}
	end
end